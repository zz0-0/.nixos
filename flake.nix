{
  description = "NixOS Flake and Home Manager configuration for zz";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:bugeats/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    creamlinux-installer = {
      url = "github:Novattz/creamlinux-installer";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      ...
    }:
    let
      username = "zz";
      system = "x86_64-linux";
      systemVersion = "26.05";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      # niri-unstable with tests disabled (failing tests on some systems with EGL display issues).
      niriPkg = (inputs.niri.lib.internal.make-package-set pkgs).niri-unstable.overrideAttrs (_: {
        doCheck = false;
      });

      # DMS Go tests bind unix sockets under TMPDIR; Nix's long build paths
      # exceed the 108-byte sockaddr_un limit and fail with EINVAL, so skip
      # checks (same rationale as niriPkg above).
      dmsPkg = (inputs.dankMaterialShell.lib.mkDmsShell pkgs).overrideAttrs (_: {
        doCheck = false;
      });

      # CreamLinux (DLC manager for Steam). WEBKIT_DISABLE_DMABUF_RENDERER is
      # required on NVIDIA systems per the upstream README.
      creamlinux = (import inputs.creamlinux-installer { inherit pkgs; }).overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/creamlinux \
            --set WEBKIT_DISABLE_DMABUF_RENDERER 1
        '';
      });

      specialArgs = {
        inherit
          username
          systemVersion
          system
          niriPkg
          dmsPkg
          creamlinux
          ;
        inherit (inputs) niri dankMaterialShell;
      };

      # Common NixOS modules shared between all hosts
      commonModules = [
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = specialArgs;

          # Required when useUserPackages is enabled for xdg portal to work
          environment.pathsToLink = [
            "/share/applications"
            "/share/xdg-desktop-portal"
          ];

          # Required by DMS greeter - use niri-unstable with tests disabled
          programs.niri = {
            enable = true;
            package = niriPkg;
          };
        }
        ({ pkgs, ... }: {
          # Portals are managed at the NixOS level. Keeping this out of
          # Home Manager avoids duplicate portal service files on D-Bus.
          xdg.portal = {
            enable = true;
            xdgOpenUsePortal = true;
            extraPortals = [
              pkgs.xdg-desktop-portal-gnome
              pkgs.xdg-desktop-portal-gtk
            ];
            config = {
              common.default = [ "gtk" ];
              niri."org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
              niri."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            };
          };
        })
      ];

      # Hosts and their module paths. Add a new host by adding one entry here.
      hosts = {
        zz = {
          description = "Original laptop";
          nixosModules = ./nixos/hosts/zz;
          homeModules = ./home-manager/hosts/zz/default.nix;
        };
        zz2 = {
          description = "New laptop (Intel Core Ultra 7 356H + NVIDIA RTX 5060)";
          nixosModules = ./nixos/hosts/zz2;
          homeModules = ./home-manager/hosts/zz2/default.nix;
        };
      };
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs (builtins.attrNames hosts) (
        name:
        nixpkgs.lib.nixosSystem {
          inherit specialArgs system;
          inherit pkgs;
          modules = [
            hosts.${name}.nixosModules
          ]
          ++ commonModules
          ++ [
            {
              home-manager.users.${username} = import hosts.${name}.homeModules;
            }
          ];
        }
      );

      # `nix flake check` builds and validates both hosts. Home Manager is
      # embedded in each NixOS system, so there is no separate HM output.
      checks.x86_64-linux = builtins.listToAttrs (
        map (name: {
          name = "nixos-${name}";
          value = self.nixosConfigurations.${name}.config.system.build.toplevel;
        }) (builtins.attrNames hosts)
      );

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages =
          with pkgs;
          [
            age
            deadnix
            nil
            nixd
            nixfmt
            sops
            statix
          ]
          ++ [ home-manager.packages.${system}.default ];
        shellHook = ''
          echo "NixOS configuration shell — nil, nixd, statix, nixfmt, deadnix"
        '';
      };

      formatter.x86_64-linux = pkgs.nixfmt-tree;
    };
}
