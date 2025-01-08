{ config, pkgs, home-manager, ... }:

{
  # Home-manager packages
  home.packages = with pkgs; [
    # Global packages
    bat
    docker
    docker-compose
    duf
    glow
    htop
    lima # VMs/Docker
    lsd
    mtr
    syncthing
    tldr
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
