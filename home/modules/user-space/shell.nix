{ config, pkgs, home-manager, ... }:

{
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
        function random-mtg-card
          set response (${pkgs.curl}/bin/curl -s "https://api.scryfall.com/cards/random")

          if test -z "$response"
            echo "Failed to fetch card from Scryfall"
            return 1
          end

          set name (echo $response | ${pkgs.jq}/bin/jq -r '.name')
          set mana_cost (echo $response | ${pkgs.jq}/bin/jq -r '.mana_cost // "N/A"')
          set type_line (echo $response | ${pkgs.jq}/bin/jq -r '.type_line')
          set oracle_text (echo $response | ${pkgs.jq}/bin/jq -r '.oracle_text // "No text"')
          set set_name (echo $response | ${pkgs.jq}/bin/jq -r '.set_name')
          set rarity (echo $response | ${pkgs.jq}/bin/jq -r '.rarity')
          set image_url (echo $response | ${pkgs.jq}/bin/jq -r '.image_uris.normal // .card_faces[0].image_uris.normal // empty')

          # Display card art using ASCII
          if test -n "$image_url"
            set temp_img (mktemp --suffix=.jpg)
            ${pkgs.curl}/bin/curl -s "$image_url" -o "$temp_img"
            ${pkgs.chafa}/bin/chafa "$temp_img" --size 60x30 --symbols ascii --colors 16
            rm "$temp_img"
            echo ""
          end

          echo "╔════════════════════════════════════════╗"
          echo "║     Random MTG Card of the Day        ║"
          echo "╚════════════════════════════════════════╝"
          echo ""
          echo "🃏 $name $mana_cost"
          echo "📋 $type_line"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo $oracle_text | fold -s -w 40
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📦 $set_name | ✨ $rarity"
          echo ""
        end

        # Show card on login (only in interactive shells)
        if status is-interactive
          random-mtg-card
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
