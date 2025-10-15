{ config, pkgs, home-manager, ... }:

{
  # Home-manager packages
  home.packages = with pkgs; [
    # Global packages
    atuin
    awscli
    bat
    caligula
    docker
    docker-compose
    dua # file size checker
    duf
    glow
    go
    kubernetes-helm
    htop
    kubectx # supplementary kubernetes tools
    lima # VMs/Docker
    localsend
    lsd
    minikube # standalone local kubernetes deployments (for testing, primarily)
    mtr
    openssl
    pv
    rig
    rustlings
    syncthing
    tldr
    todoist
    tree
    zellij
    zoxide

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
#   hyprland
    hyprlock
    hyprpaper
    libvirt
    polonium
    swayosd
    ulauncher
    waybar
  ] ++ lib.optionals stdenv.isDarwin [
    # MacOS-specific packages
    mas
    m-cli
    pinentry_mac
  ];
}
