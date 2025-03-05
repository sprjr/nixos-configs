{ config, pkgs, home-manager, ... }:

{
  # Home-manager packages
  home.packages = with pkgs; [
    # Global packages
    bat
    cool-retro-term
    cowsay
    docker
    docker-compose
    duf
    figlet
    fortune
    glow
    htop
    lima # VMs/Docker
    lolcat
    lsd
    mtr
    syncthing
    ternimal
    tldr
    tree
    zellij
  ] ++ lib.optionals stdenv.isLinux [
    # Linux-specific packages
    anki
    firefox
    libvirt
  ] ++ lib.optionals stdenv.isDarwin [
    # MacOS-specific packages
    mas
    m-cli
    pinentry_mac
  ];
}
