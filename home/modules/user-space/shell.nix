{ config, pkgs, home-manager, ... }:

{

  starship_config = pkgs.writeText "starship.toml" ''
    [character]
    success_symbol = '[❯](bold white)'

    [container]
    disabled = true
  '';
  aws_config = pkgs.writeText "aws.fish" ''
    if test -z "$AWS_CONFIG_FILE"
      set -gx AWS_CONFIG_FILE "$HOME/.aws/config"
    end

    # Helper function to get aws-profiles
    function _get_aws_profiles
      if grep -q '\[profile ' "$AWS_CONFIG_FILE"
        set -x aws_profiles "$(${pkgs.gnugrep}/bin/grep '\[profile' $AWS_CONFIG_FILE)"
        set -x aws_profiles "$(echo $aws_profiles | ${pkgs.gnused}/bin/sed 's/\[profile //g' | ${pkgs.gnused}/bin/sed 's/\]//g')"
        echo $aws_profiles
      end
    end

    # Function to easily switch aws profiles in config
    function asp
      if test -e "$AWS_CONFIG_FILE"
        set -x aws_profiles "$(${pkgs.gnugrep}/bin/grep '\[profile' $AWS_CONFIG_FILE)"
        set -x aws_profiles "$(echo $aws_profiles | ${pkgs.gnused}/bin/sed 's/\[profile //g' | ${pkgs.gnused}/bin/sed 's/\]//g')"
        set -x profile_selection "$argv[1]"
        if test -z "$profile_selection"
          set -x profile_selection "$(echo $aws_profiles | ${pkgs.coreutils}/bin/tr " " "\n" | ${pkgs.fzf}/bin/fzf)"
        end
        test -n "$profile_selection" && echo "$aws_profiles" | ${pkgs.gnugrep}/bin/grep -q "$profile_selection" && set -gx AWS_PROFILE "$profile_selection"
      end
    end

    # Autocompletion for asp
    complete -e asp
    if test -e "$AWS_CONFIG_FILE"
      complete -x -c asp -d "AWS profiles" -n "_get_aws_profiles" -a "$(_get_aws_profiles)"
    end
  '';

  # .bashrc configuration
  programs = {
    # Enable Starship
    starship = {
      enable = true;
      settings = {
        aws = {
          format = "[$symbol$profile]($style)";
          disabled = true;
        };
      };
    };
    # Bash/Starship
    bash = {
      enable = true;
      # Terminal startup tasks
      bashrcExtra = ''
        # Define cht function (cheat.sh helper)
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
      # Aliases
      shellAliases = {
        bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
        cat = "bat";
        comfin = "paplay /home/patrick/Documents/Obs-Studio/halo_game-over.mp3";
        compose2nix-start = "nix shell github:aksiksi/compose2nix";
        df = "duf";
        dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
        dockername = "docker inspect --format='{{.Name}}' $(sudo docker ps -aq --no-trunc)";
        hmrb = "nix run nixpkgs#home-manager -- build -f ./home/home.nix";
        kubectl = "sudo k3s kubectl";
        ls = "lsd -l";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
        yt-dl = "nix-shell -p yt-dlp";

        # For fun/dumb aliases
        anaconda = "ternimal length=100 thickness=1,4,1,0,0 radius=6,12 gradient=0:#666600,0.5:#00ff00,1:#003300";
        rainbow = "ternimal length=20 thickness=70,15,0,1,0 padding=10 radius=5 gradient=0.03:#ffff00,0.15:#0000ff,0.3:#ff0000,0.5:#00ff00";
        swarm = "ternimal length=200 thickness=0,4,19,0,0";
      };
    };
    zsh = {
      enable = true;
      initContent = ''
        # Run fish if it's not already running
        if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]
        then
          exec fish -l
        fi
        export TERM=screen-256color
      '';
      shellAliases = {
        bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
        cat = "bat";
        compose2nix-start = "nix shell github:aksiksi/compose2nix";
        df = "duf";
        dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
        dockername = "docker inspect --format='{{.Name}}' $(sudo docker ps -aq --no-trunc)";
        hmrb = "nix run nixpkgs#home-manager -- build -f ./home/home.nix";
        kubectl = "k3s kubectl";
        ls = "lsd -l";
        tree = "tree -C";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
        yt-dl = "nix-shell -p yt-dlp";
        cdn = "cd ~/.nixos-configuration/nixos-configs/";

        # For fun/dumb aliases
        anaconda = "ternimal length=100 thickness=1,4,1,0,0 radius=6,12 gradient=0:#666600,0.5:#00ff00,1:#003300";
        rainbow = "ternimal length=20 thickness=70,15,0,1,0 padding=10 radius=5 gradient=0.03:#ffff00,0.15:#0000ff,0.3:#ff0000,0.5:#00ff00";
        swarm = "ternimal length=200 thickness=0,4,19,0,0";
      };
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # disable greeting
        # direnv
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
      # Aliases
      shellAliases = {
        bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
        cat = "bat";
        compose2nix-start = "nix shell github:aksiksi/compose2nix";
        comfin = "paplay /home/patrick/Documents/Obs-Studio/halo_game-over.mp3";
        df = "duf";
        dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
        dockername = "docker inspect --format='{{.Name}}' $(sudo docker ps -aq --no-trunc)";
        docres = "docker restart $(docker ps -q)";
        hmrb = "nix run nixpkgs#home-manager -- build -f ./home/home.nix";
        kubectl = "k3s kubectl";
        ls = "lsd -l";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
        yt-dl = "nix-shell -p yt-dlp";

        # For fun/dumb aliases
        anaconda = "ternimal length=100 thickness=1,4,1,0,0 radius=6,12 gradient=0:#666600,0.5:#00ff00,1:#003300";
        rainbow = "ternimal length=20 thickness=70,15,0,1,0 padding=10 radius=5 gradient=0.03:#ffff00,0.15:#0000ff,0.3:#ff0000,0.5:#00ff00";
        swarm = "ternimal length=200 thickness=0,4,19,0,0";
      };
    };
  };
}
