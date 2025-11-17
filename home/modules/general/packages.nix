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
    htop
    kubernetes-helm
    kubectx # supplementary kubernetes tools
    lazydocker
    lazygit
    lima # VMs/Docker
    localsend
    lsd
    minikube # standalone local kubernetes deployments (for testing, primarily)
    mtr
    nrf-command-line-tools
    openssl
    pv
    rig
    rustlings
    syncthing
    tldr
    todoist
    tree
    yazi
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
    impala
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
