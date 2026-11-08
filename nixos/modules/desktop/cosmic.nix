{ pkgs, ... }:

{
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
