{
  description = "example nixos/nix-darwin/home-manager/nix-droid flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "gitlab:kylesferrazza/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{  self,
                      nixpkgs,
                      nixpkgs-stable,
                      flake-utils,
                      darwin,
                      home-manager,
                      spicetify-nix,
                      ... }:
  let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    system = pkgs.system;
    pkgs-stable = nixpkgs-stable.legacyPackages.${system};
  in {
    # nixos targets
    nixosConfigurations = {
      trixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./nixos/hardware-configuration/trixos.nix
          ./nixos/desktop.nix
          ./nixos/modules/nvidia.nix
          {
            networking.hostName = "trixos";
            hardware.nvidia.prime = {
              # Verify BUS ID
              intelBusId = "PCI:0:2:0";
              nvidiaBusId = "PCI:1:0:0";
            };
            environment.systemPackages = with pkgs; [
              cockpit
              ### Lutris ###
              (lutris.override {
                 extraPkgs = pkgs: [
                   # List package dependencies here
                 ];
              })
              ### Wine ###
              (wineWowPackages.full.override {
                wineRelease = "staging";
                mingwSupport = true;
              })
              winetricks
              spicetify-nix.packages.x86_64-linux.nord
            ];
            services.openssh.enable = true;
          }
        ];
      };

      seanix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./nixos/hardware-configuration/seanix.nix
          ./nixos/gaming-desktop.nix
          ./nixos/modules/shell/starship.nix
          ./nixos/modules/virtualisation/containers/syncthing.nix
          ./nixos/modules/gaming/sunshine.nix
          ./nixos/modules/monitoring/node-exporter.nix
          {
          # Additional configuration goes here
          }
        ];
      };

    # Darwin
    darwinConfigurations = {
      # m2-macbook-air 
      "seair" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs;
        modules = [ ./hosts/seair.nix ];
      };
    };

    # home-manager targets (non NixOS/MacOS)
    homeConfigurations = {
      patrick = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = inputs;
        modules = [
          ./home/home.nix
          {
            home = {
              username = "patrick";
              homeDirectory = "/home/patrick";
            };
            fonts.fontconfig.enable = true;
            programs.home-manager.enable = true;
            targets.genericLinux.enable = true;
            home.packages = [
              (pkgs.nerdfonts.override { fonts = [ "Hack" "DroidSansMono" "JetBrainsMono" ]; })
            ];
          }
        ];
      };
    };
  };
}
