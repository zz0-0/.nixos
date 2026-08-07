{
  description = "NixOS Flake and Home Manager configuration for zz";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devshell = {
      url = "github:zz0-0/.devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      devshell,
      dankMaterialShell,
      niri,
      ...
    }:
    let
      username = "zz";
      system = "x86_64-linux";
      systemVersion = "26.05";

      # Restore libdisplay-info 0.2.0 (removed from nixpkgs 2026-08-04).
      # niri-flake's make-niri asserts version == "0.2.0"; remove once upstream
      # niri-flake stops pinning it.
      libdisplayInfoOverlay = final: prev: {
        libdisplay-info_0_2 = prev.stdenv.mkDerivation {
          pname = "libdisplay-info";
          version = "0.2.0";
          src = prev.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "emersion";
            repo = "libdisplay-info";
            tag = "0.2.0";
            hash = "sha256-6xmWBrPHghjok43eIDGeshpUEQTuwWLXNHg7CnBUt3Q=";
          };
          strictDeps = true;
          __structuredAttrs = true;
          depsBuildBuild = [ prev.pkg-config ];
          nativeBuildInputs = [
            prev.meson
            prev.pkg-config
            prev.ninja
            prev.hwdata
            prev.python3
          ];
          postPatch = ''
            patchShebangs tool/gen-search-table.py
          '';
          meta = {
            description = "EDID and DisplayID library";
            homepage = "https://gitlab.freedesktop.org/emersion/libdisplay-info";
            license = prev.lib.licenses.mit;
            platforms = prev.lib.platforms.linux ++ prev.lib.platforms.freebsd;
          };
        };
      };

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
        overlays = [ libdisplayInfoOverlay ];
      };

      # niri-unstable with tests disabled (failing tests on some systems with EGL display issues).
      # Built via the flake's make-package-set so it picks up the libdisplay-info overlay.
      niriPkg = (inputs.niri.lib.internal.make-package-set pkgs).niri-unstable.overrideAttrs (_: {
        doCheck = false;
      });

      specialArgs = {
        inherit
          username
          systemVersion
          system
          niriPkg
          ;
        niri = inputs.niri;
        dankMaterialShell = inputs.dankMaterialShell;
      };

      # Common NixOS modules shared between all hosts
      commonModules = [
        home-manager.nixosModules.home-manager
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
          # xdg-desktop-portal-gnome is required for screencasting on niri
          xdg.portal = {
            enable = true;
            extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
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
          description = "New laptop (Intel i7-358H + NVIDIA RTX 5060)";
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
          pkgs = pkgs;
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

      homeConfigurations = nixpkgs.lib.genAttrs (builtins.attrNames hosts) (
        name:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ hosts.${name}.homeModules ];
          extraSpecialArgs = specialArgs;
        }
      );

      # `nix flake check` builds and validates all hosts
      checks.x86_64-linux = builtins.listToAttrs (
        builtins.concatLists (
          map (name: [
            {
              name = "nixos-${name}";
              value = self.nixosConfigurations.${name}.config.system.build.toplevel;
            }
            {
              name = "home-${name}";
              value = self.homeConfigurations.${name}.activationPackage;
            }
          ]) (builtins.attrNames hosts)
        )
      );

      devShells.x86_64-linux.default = devshell.lib.x86_64-linux.nix {
        extraPackages = [ home-manager.packages.${system}.default ];
      };
    };
}
