{ config, pkgs, home-manager, ... }:

{
  # Home-manager packages
  home.packages = with pkgs; [
    # Global packages
    _1password-cli
    _1password-gui
    andcli
    atuin
    awscli
    bat
    caligula
    direnv
    docker
    docker-compose
    dua # file size checker
    duf
    glow
    gocheat
    harper
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
    nps
    openssl
    pv
    rig
    russ
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
    blahaj
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
#   _1password-gui
#   _1password-cli
    anki
    firefox
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
