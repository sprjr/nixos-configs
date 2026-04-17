{ config, pkgs, ... }:

{
  imports = [
    ./modules/tools/helix/config.nix
    ./modules/tools/helix/languages.nix
    ./modules/tools/helix/theme-nord.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/btop.nix
    ./modules/user-space/zellij/zellij-config.nix
    ./modules/user-space/zellij/zellij-layout.nix
  ];

  home.packages = with pkgs; [
    atuin
    awscli2
    bat
    chafa
    direnv
    dua
    duf
    glow
    gocheat
    htop
    btop
    jq
    kubernetes-helm
    kubectx
    lazygit
    lsd
    mtr
    openssl
    pv
    rig
    russ
    rustlings
    syncthing
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
    vscode-langservers-extracted
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
    ternimal
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

    bash = {
      enable = true;
      bashrcExtra = ''
        cht() {
          if [ $# -eq 0 ]; then
            printf 'usage: cht <query>\n' >&2
            return 1
          fi
          local encoded
          encoded=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(" ".join(sys.argv[1:])))' "$@")
          curl "https://cht.sh/$encoded"
        }
      '';
      shellAliases = {
        bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
        cat = "bat";
        df = "duf";
        dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
        ls = "lsd -l";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
        hmrb = "nix-on-droid switch --flake ~/.nixos/nixos-configs#droid";
        anaconda = "ternimal length=100 thickness=1,4,1,0,0 radius=6,12 gradient=0:#666600,0.5:#00ff00,1:#003300";
        rainbow = "ternimal length=20 thickness=70,15,0,1,0 padding=10 radius=5 gradient=0.03:#ffff00,0.15:#0000ff,0.3:#ff0000,0.5:#00ff00";
        swarm = "ternimal length=200 thickness=0,4,19,0,0";
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
        anaconda = "ternimal length=100 thickness=1,4,1,0,0 radius=6,12 gradient=0:#666600,0.5:#00ff00,1:#003300";
        rainbow = "ternimal length=20 thickness=70,15,0,1,0 padding=10 radius=5 gradient=0.03:#ffff00,0.15:#0000ff,0.3:#ff0000,0.5:#00ff00";
        swarm = "ternimal length=200 thickness=0,4,19,0,0";
      };
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting
        eval (${pkgs.direnv}/bin/direnv hook fish)
        if status is-interactive
          eval (zellij setup --generate-auto-start fish | string collect)
        end
        function cht
          if test (count $argv) -eq 0
            printf 'usage: cht <query>\n' >&2
            return 1
          end
          set encoded (python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(" ".join(sys.argv[1:])))' $argv)
          curl "https://cht.sh/$encoded"
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
        anaconda = "ternimal length=100 thickness=1,4,1,0,0 radius=6,12 gradient=0:#666600,0.5:#00ff00,1:#003300";
        rainbow = "ternimal length=20 thickness=70,15,0,1,0 padding=10 radius=5 gradient=0.03:#ffff00,0.15:#0000ff,0.3:#ff0000,0.5:#00ff00";
        swarm = "ternimal length=200 thickness=0,4,19,0,0";
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
