{ nixos-cosmic, pkgs, ... }:

{
  imports = [ nixos-cosmic.nixosModules.default ];

  nixpkgs.overlays = [ nixos-cosmic.overlays.default ];

  nix.settings = {
    substituters = [ "https://cosmic.cachix.org" ];
    trusted-public-keys = [ "cosmic.cachix.org-1:Dya6IxT5r5k6SJOsGKFGMEMQDcWlBoAN1JgaoL/hMKE=" ];
  };

  services = {
    desktopManager.cosmic.enable = true;
    displayManager.cosmic-greeter.enable = true;
    # Disable Orca screen reader that can mistakenly start enabled by default on Cosmic
    orca.enable = false;
    libinput.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security.rtkit.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  networking.networkmanager.enable = true;

  # JetBrains Mono Nerd Font is used by the Cosmic user-space config
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
