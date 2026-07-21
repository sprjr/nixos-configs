{
  config,
  pkgs,
  home-manager,
  ...
}:

{
  # Home-manager packages
  home.packages =
    with pkgs;
    [
      # Global packages
      alacritty
      andcli
      attic-client
      atuin
      awscli2
      bat
      caligula
      chafa # (in-shell image handling)
      direnv
      docker
      docker-compose
      dua # file size checker
      duf
      ffmpeg
      fzf
      gh
      gh-dash
      glow
      gocheat
      harper
      helix
      htop
      jq
      kubernetes-helm
      kubectx # supplementary kubernetes tools
      lazydocker
      lazygit
      lima # VMs/Docker
      localsend
      lsd
      mdp
      minikube # standalone local kubernetes deployments (for testing, primarily)
      mtr
      nebula
      nps
      openssl
      opentofu
      pv
      python314
      python314Packages.pip
      stirling-pdf-desktop
      rig
      russ
      rustlings
      syncthing
      terraformer
      tldr
      tmux
      todoist
      tree
      xclip
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
    ]
    ++ lib.optionals stdenv.isLinux [
      # Linux-specific packages
      android-tools
      bandwhich
      duplicati
      firefox
      ghostty
      google-chrome
      impala
      inetutils
      kitty
      legcord
      libusb1
      libvirt
      meson
      moonlight-qt
      mullvad-vpn
      mumble
      nethogs
      netop
      nextcloud-client
      nmap
      obsidian
      pkg-config
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
      wireguard-tools
      wireguard-ui
      wireshark
      xpipe
    ]
    ++ lib.optionals stdenv.isDarwin [
      # MacOS-specific packages
      mas
      m-cli
      pinentry_mac
    ];
}
