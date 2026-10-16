{ config, pkgs, ... }:

{
  imports = [
    ./modules/tools/helix/config.nix
    ./modules/tools/helix/languages.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/zellij/zellij-config.nix
    ./modules/user-space/zellij/zellij-layout.nix
  ];

  home.packages = with pkgs; [
    atuin
    bat
    chafa
    direnv
    dua
    duf
    glow
    htop
    btop
    jq
    lazygit
    lsd
    mtr
    openssl
    pv
    tldr
    tree
    yazi
    zellij
    zoxide
    # LSP servers
    bash-language-server
    nil
    nixfmt
    pyright
    ruff
    shellcheck
    taplo
    yaml-language-server
    marksman
    # Fun CLI
    asciiquarium
    blahaj
    cbonsai
    cmatrix
    cowsay
    figlet
    fortune
    lavat
    lolcat
    nms
    sl
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "sprjr";
        email = "patrick@rawlinson.ws";
      };
    };
  };

  programs.helix.enable = true;

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  programs = {
    starship = {
      enable = true;
      settings = {
        aws = {
          format = "[$symbol$profile]($style)";
          disabled = true;
        };
      };
    };

    zsh = {
      enable = true;
      initContent = ''
        if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]
        then
          exec fish -l
        fi
        export TERM=screen-256color
      '';
      shellAliases = {
        bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
        cat = "bat";
        df = "duf";
        dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
        ls = "lsd -l";
        tree = "tree -C";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
        hmrb = "nix-on-droid switch --flake ~/.nixos/nixos-configs#droid";
      };
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting
        eval (${pkgs.direnv}/bin/direnv hook fish)
        if status is-interactive; and not set -q ZELLIJ
            if test -n "$SSH_CONNECTION"
                zellij --layout remote
            else
                zellij
            end
        end
      '';
      shellAliases = {
        bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
        cat = "bat";
        df = "duf";
        dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
        ls = "lsd -l";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
        hmrb = "nix-on-droid switch --flake ~/.nixos/nixos-configs#droid";
      };
    };
  };

  home.username = "nix-on-droid";
  home.homeDirectory = "/data/data/com.termux.nix/files/home";

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  home.stateVersion = "24.05";
}
