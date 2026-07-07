{
  description = "sprjr nix configs flake";

  inputs = {
    # Nix stuff
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    # Other
    heywoodlh-configs.url = "github:heywoodlh/nixos-configs/699bb88";
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprsession = {
      url = "github:tiecia/hyprsession";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nvidia-patch = {
      url = "github:icewind1991/nvidia-patch-nixos";
      inputs.nixpkgs.follows = "flake-utils";
    };
    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "gitlab:kylesferrazza/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    thyx = {
      url = "github:rccyx/thyx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    weathr = {
      url = "github:Veirt/weathr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Custom stuff
    dark-wallpaper-laptop = {
      url = "https://raw.githubusercontent.com/dharmx/walls/refs/heads/main/nord/a_cartoon_of_a_spider_man.jpg";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      comin,
      darwin,
      flake-utils,
      ghostty,
      heywoodlh-configs,
      home-manager,
      hyprsession,
      nix-cachyos-kernel,
      nix-on-droid,
      nixos-hardware,
      omarchy-nix,
      sops-nix,
      thyx,
      nixpkgs,
      nixpkgs-stable,
      spicetify-nix,
      weathr,
      dark-wallpaper-laptop,
      ...
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        # nixos targets
        packages.nixosConfigurations = {
          nx-01 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs;
            modules = [
              comin.nixosModules.comin
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              ./nixos/hardware-configuration/nx-01.nix
              ./nixos/modules/desktop/cosmic.nix
              ./nixos/nx-01.nix
              ./nixos/modules/desktop/hyprland.nix
              #./nixos/modules/system/attic-cache.nix
              ./nixos/modules/system/comin.nix
              ./nixos/modules/system/comin-notify.nix
              ./nixos/modules/network/wifi.nix
              ./nixos/modules/user/patrick.nix
              ./nixos/modules/homelab/syncthing-client-preset.nix
            ];
          };
          trixos = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs;
            modules = [
              sops-nix.nixosModules.sops
              /etc/nixos/hardware-configuration.nix
              ./nixos/trixos.nix
              ./nixos/modules/nvidia.nix
              ./nixos/modules/monitoring/node-exporter.nix
              ./nixos/modules/system/sops.nix
              ./nixos/modules/homelab/syncthing-client-preset.nix
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
                  (wineWow64Packages.full.override {
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
              comin.nixosModules.comin
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              ./nixos/hardware-configuration/prometheus.nix
              ./nixos/prometheus.nix
              ./nixos/modules/desktop/hyprland.nix
              #./nixos/modules/system/attic-cache.nix
              ./nixos/modules/system/comin.nix
              ./nixos/modules/system/comin-notify.nix
              ./nixos/modules/network/wifi.nix
              ./nixos/modules/user/patrick.nix
              ./nixos/modules/homelab/syncthing-client-preset.nix
            ];
          };
          seanix = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs;
            modules = [
              comin.nixosModules.comin
              sops-nix.nixosModules.sops
              thyx.nixosModules.default
              ./nixos/hardware-configuration/seanix.nix
              ./nixos/seanix.nix
              ./nixos/modules/desktop/hyprland.nix
              ./nixos/modules/system/sops.nix
              ./nixos/modules/network/wifi.nix
              ./nixos/modules/homelab/syncthing-client-preset.nix
              ./nixos/modules/gaming/sunshine.nix
              ./nixos/modules/gaming/cachyos-gaming.nix
              ./nixos/modules/disks/seanix-mount.nix
              ./nixos/modules/homelab/ollama-nvidia.nix
              #./nixos/modules/system/attic-cache.nix
              ./nixos/modules/system/comin.nix
              ./nixos/modules/system/comin-notify.nix
              ./nixos/modules/system/nvidia-seanix.nix
              ./nixos/modules/system/udev-scrcpy.nix
              ./nixos/modules/user/patrick-desktop.nix
            ];
          };
          shikisha = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs;
            modules = [
              comin.nixosModules.comin
              sops-nix.nixosModules.sops
              ./nixos/hardware-configuration/shikisha.nix
              ./nixos/shikisha.nix
              ./nixos/modules/disks/unraid-docker.nix
              ./nixos/modules/disks/unraid-gitea.nix
              ./nixos/modules/disks/unraid-other.nix
              ./nixos/modules/disks/unraid-kubernetes.nix
              ./nixos/modules/disks/unraid-nextcloud.nix
              ./nixos/hosts/shikisha/cron/authentik-backup.nix
              ./nixos/hosts/shikisha/cron/podcast-downloader.nix
              #./nixos/modules/network/scripts/net_watchdog.nix
              #./nixos/modules/homelab/attic.nix
              #./nixos/modules/system/attic-cache.nix
              ./nixos/modules/homelab/nextcloud.nix
              ./nixos/modules/homelab/storage/garage-systemd-service.nix
              #./nixos/modules/homelab/certbot-mumble.nix
              ./nixos/modules/homelab/mosquitto.nix
              ./nixos/modules/system/comin.nix
              ./nixos/modules/system/comin-notify.nix
              ./nixos/modules/system/sops.nix
              ./nixos/modules/virtualisation/k3s-server.nix
              ./nixos/modules/user/patrick.nix
            ];
          };
          voyager = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs;
            modules = [
              comin.nixosModules.comin
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              ./nixos/hardware-configuration/voyager.nix
              ./nixos/voyager.nix
              ./nixos/modules/desktop/cosmic.nix
              ./nixos/modules/desktop/hyprland.nix
              #./nixos/modules/system/attic-cache.nix
              ./nixos/modules/system/comin.nix
              ./nixos/modules/system/comin-notify.nix
              ./nixos/modules/system/fprintd.nix
              ./nixos/modules/network/wifi.nix
              ./nixos/modules/user/patrick.nix
              ./nixos/modules/homelab/syncthing-client-preset.nix
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
              sops-nix.darwinModules.sops
              ./darwin/modules/sops.nix
              ./darwin/hosts/seair.nix
              {
                networking.hostName = "seair";
              }
            ];
          };
          # m4-macbook-air
          "defiant" = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = inputs;
            modules = [
              sops-nix.darwinModules.sops
              ./darwin/modules/sops.nix
              ./darwin/hosts/defiant.nix
              {
                networking.hostName = "defiant";
                ids.gids.nixbld = 350;
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
              ./home/home.nix
              {
                home = {
                  username = "patrick";
                  homeDirectory = "/home/patrick";
                };
                fonts.fontconfig.enable = true;
                programs.home-manager.enable = true;
                targets.genericLinux.enable = true;
              }
            ];
          };
        };
      }
    ))
    // {
      nixOnDroidConfigurations.droid = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        modules = [ ./nixos/droid.nix ];
        extraSpecialArgs = inputs;
        home-manager-path = home-manager.outPath;
      };
    };
}
