{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Headless-safe: everything here must work without a display.
  home.packages =
    with pkgs;
    [
      andcli
      attic-client
      atuin
      btop
      awscli2
      caligula
      chafa
      direnv
      discordo
      docker
      docker-compose
      dua
      duf
      ffmpeg
      fzf
      gh
      gh-dash
      glow
      gocheat
      harper
      helix
      himalaya
      htop
      jq
      kubernetes-helm
      kubectx
      lazydocker
      lazygit
      lima
      lsd
      mdp
      minikube
      mtr
      nebula
      nps
      opencode
      openssl
      opentofu
      pv
      python314
      python314Packages.pip
      rig
      russ
      syncthing
      terraformer
      termshark
      tldr
      tmux
      todoist
      tree
      typst
      yazi
      zellij
      zoxide
      asciiquarium
      blahaj
      cbonsai
      cmatrix
      cowsay
      figlet
      lavat
      lolcat
      nms
      sl
      ternimal
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      android-tools
      bandwhich
      duplicati
      dust
      fortune
      impala
      inetutils
      libusb1
      libvirt
      meson
      nethogs
      netop
      nmap
      pkg-config
      (pkgs.callPackage ../../../pkgs/spacescan { })
      wireguard-tools
      wireguard-ui
      (pkgs.callPackage ../../../pkgs/xurl { })
    ];

  xdg.configFile."glow/glow.yml".text = ''
    pager: true
  '';
}
