{ pkgs, ... }:

{
  # Packages available outside home-manager (needed by activation/login).
  environment.packages = with pkgs; [
    curl
    fd
    fish
    git
    gnupg
    jq
    nixfmt
    openssh
    ripgrep
    rsync
    unzip
  ];

  user.shell = "${pkgs.fish}/bin/fish";

  # Everything nix-on-droid can actually reach on the Android side.
  # termux-api (notifications, sensors, battery, sms) is NOT available here:
  # upstream ships no termux-api and the Termux:API app only trusts com.termux.
  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-setup-storage.enable = true;
    termux-reload-settings.enable = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
    xdg-open.enable = true;
  };

  home-manager.config = ../home/droid-home.nix;
  home-manager.useGlobalPkgs = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "24.05";
}
