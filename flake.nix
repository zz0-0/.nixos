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
      url = "github:zz0-0/devshell";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      devshell,
      dankMaterialShell,
      ...
    }:
    let
      username = "zz";
      system = "x86_64-linux";
      systemVersion = "26.05";
      specialArgs = {
        inherit username systemVersion;
        niri = inputs.niri;
        dankMaterialShell = inputs.dankMaterialShell;
      };
    in
    {
      nixosConfigurations = {
        zz = nixpkgs.lib.nixosSystem {
          inherit specialArgs system;
          modules = [
            ./hosts/${username}
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.${username} = import ./home-manager/default.nix;

              # Required when useUserPackages is enabled for xdg portal to work
              environment.pathsToLink = [
                "/share/applications"
                "/share/xdg-desktop-portal"
              ];

              # Required by DMS greeter
              programs.niri.enable = true;
            }
          ];
        };
      };

      homeConfigurations = {
        zz = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
          modules = [ ./home-manager/default.nix ];
          extraSpecialArgs = specialArgs;
        };
      };

      devShells.x86_64-linux.default = devshell.lib.x86_64-linux.nix {
        extraPackages = [ home-manager.packages.${system}.default ];
      };
    };
}
