{ config, pkgs, home-manager, ... }:

{
  # Home-manager packages
  home.packages = with pkgs; [
    # Global packages
    1password
    bat
    docker
    docker-compose
    dua # file size checker
    duf
    glow
    htop
    lima # VMs/Docker
    lsd
    mtr
    pv
    rig
    syncthing
    tldr
    tree
    zellij

    # Dumb CLI tools
    asciiquarium
    cbonsai
    cmatrix
    cool-retro-term
    cowsay
    figlet
    fortune
    lavat
    lolcat
    nms
    sl
    ternimal
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
