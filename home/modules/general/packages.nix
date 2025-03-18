{ config, pkgs, home-manager, ... }:

{
  # Home-manager packages
  home.packages = with pkgs; [
    # Global packages
    _1password-gui
    _1password-cli
    bat
    docker
    docker-compose
    dua # file size checker
    duf
    glow
    go
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
    polonium
  ] ++ lib.optionals stdenv.isDarwin [
    # MacOS-specific packages
    mas
    m-cli
    pinentry_mac
  ];
}
