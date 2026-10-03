{
  config,
  pkgs,
  lib,
  ...
}:

{
  # GUI/desktop-only packages. Never import this from a headless server profile.
  home.packages =
    with pkgs;
    [
      alacritty
      cool-retro-term
      localsend
      xclip
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      firefox
      ghostty
      google-chrome
      kitty
      legcord
      moonlight-qt
      mullvad-vpn
      mumble
      nextcloud-client
      obsidian
      prismlauncher
      remmina
      scrcpy
      signal-desktop
      solaar
      swayosd
      thunderbird
      ulauncher
      vlc
      waybar
      wireshark
      xpipe
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      mas
      m-cli
      pinentry_mac
    ];
}
