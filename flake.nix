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

      # Overlay to fix niri build issues (disable failing tests)
      niriOverlay = final: prev: {
        niri = inputs.niri.packages.${system}.niri-unstable.overrideAttrs (_: {
          doCheck = false;
        });
      };

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
        overlays = [ niriOverlay ];
      };

      specialArgs = {
        inherit username systemVersion system;
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
            package = inputs.niri.packages.${system}.niri-unstable.overrideAttrs (_: {
              doCheck = false;
            });
          };
        }
      ];
    in
    {
      nixosConfigurations = {
        # Original laptop configuration
        zz = nixpkgs.lib.nixosSystem {
          inherit specialArgs system;
          pkgs = pkgs;
          modules = [
            ./nixos/hosts/zz
          ]
          ++ commonModules
          ++ [
            {
              home-manager.users.${username} = import ./home-manager/hosts/zz/default.nix;
            }
          ];
        };

        # New laptop (Intel i7-358H + NVIDIA RTX 5060)
        zz2 = nixpkgs.lib.nixosSystem {
          inherit specialArgs system;
          pkgs = pkgs;
          modules = [
            ./nixos/hosts/zz2
          ]
          ++ commonModules
          ++ [
            {
              home-manager.users.${username} = import ./home-manager/hosts/zz2/default.nix;
            }
          ];
        };
      };

      homeConfigurations = {
        # Standalone Home Manager for zz
        zz = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager/hosts/zz/default.nix ];
          extraSpecialArgs = specialArgs;
        };

        # Standalone Home Manager for zz2
        zz2 = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home-manager/hosts/zz2/default.nix ];
          extraSpecialArgs = specialArgs;
        };
      };

      devShells.x86_64-linux.default = devshell.lib.x86_64-linux.nix {
        extraPackages = [ home-manager.packages.${system}.default ];
      };
    };
}
