{
  description = "sprjr nixos configs flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    heywoodlh-configs.url = "github:heywoodlh/nixos-configs/699bb88";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fish-flake = {
      url = "./flakes/fish";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "gitlab:kylesferrazza/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{  self,
                      darwin,
                      fish-flake,
                      flake-utils,
                      ghostty,
                      heywoodlh-configs,
                      home-manager,
                      nixos-hardware,
                      sops-nix,
                      nixpkgs,
                      nixpkgs-stable,
                      spicetify-nix,
                      ... }:
  flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    # nixos targets
    packages.nixosConfigurations = {
      trixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./nixos/hardware-configuration/trixos.nix
          ./nixos/trixos.nix
          ./nixos/modules/nvidia.nix
          ./nixos/modules/monitoring/node-exporter.nix
         #./nixos/modules/backups/rsnapshot.nix
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
      prometheus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          sops-nix.nixosModules.sops
          ./nixos/hardware-configuration/prometheus.nix
          ./nixos/prometheus.nix
          ./nixos/modules/user/patrick.nix
          {
          # Additional configuration goes here
          }
        ];
      };

      seanix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
           sops-nix.nixosModules.sops
          ./nixos/hardware-configuration/seanix.nix
          ./nixos/seanix.nix
          ./nixos/modules/virtualisation/containers/syncthing.nix
          ./nixos/modules/virutalisation/k3s-node.nix
	  ./nixos/modules/virtualisation/ollama.nix
	  ./nixos/modules/gaming/sunshine.nix
          ./nixos/modules/disks/seanix-mount.nix # not automounting yet
          ./nixos/modules/system/udev-scrcpy.nix
          ./nixos/modules/user/patrick.nix
          {
          # Additional configuration goes here
          }
        ];
      };

      seanvy = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./nixos/hardware-configuration/seanvy.nix
          ./nixos/hp-envy.nix
          ./nixos/modules/virtualisation/containers/syncthing.nix
        ];
      };

      shikisha = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
           sops-nix.nixosModules.sops
          ./nixos/hardware-configuration/shikisha.nix
          ./nixos/shikisha.nix
          ./nixos/modules/system/sops.nix
          ./nixos/modules/virtualisation/containers/syncthing.nix
         #./nixos/modules/virtualisation/k3s-node.nix
          ./nixos/modules/virtualisation/k3s-server.nix
	  ./nixos/modules/user/patrick.nix
        ];
      };
    };

    # Darwin
    packages.darwinConfigurations = {
      # m2-macbook-air
      "seair" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs;
        modules = [
          ./darwin/base.nix
          {
            # Set hostname
            networking.hostName = "seair";
          }
        ];
      };
    };

    # home-manager targets (non NixOS/MacOS)
    packages.homeConfigurations = {
      patrick = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = inputs;
        modules = [
          ./home/darwin-home.nix
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
  });
}
