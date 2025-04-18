{ config, pkgs, home-manager, ... }:

{
  # Home-manager packages
  home.packages = with pkgs; [
    # Global packages
    ansible
    atuin
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
    minikube
    mtr
    pv
    rig
    rustlings
    syncthing
    tldr
    todoist
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
    _1password-gui
    _1password-cli
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
