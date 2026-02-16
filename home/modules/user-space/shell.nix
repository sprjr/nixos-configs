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
          set cache_dir "$HOME/.cache/scryfall"
          set bulk_cache "$cache_dir/cards.json"
          set daily_card "$cache_dir/card-of-day.json"
          set today (date +%Y-%m-%d)

          # Create cache directory
          mkdir -p "$cache_dir"

          # Check if we need a new card (different day or file doesn't exist)
          set needs_new_card true
          if test -f "$daily_card"
            set cached_date (${pkgs.jq}/bin/jq -r '.cached_date // ""' "$daily_card")
            if test "$cached_date" = "$today"
              set needs_new_card false
            end
          end

          # Get new card if needed
          if test "$needs_new_card" = true
            # Download bulk data if not present or older than 7 days
            if not test -f "$bulk_cache"; or test (find "$bulk_cache" -mtime +7 2>/dev/null | wc -l) -gt 0
              echo "Updating card database (one-time download)..."
              set bulk_data_url (${pkgs.curl}/bin/curl -s "https://api.scryfall.com/bulk-data/default-cards" | ${pkgs.jq}/bin/jq -r '.download_uri')                                                                                                                                    ${pkgs.curl}/bin/curl -s "$bulk_data_url" -o "$bulk_cache"
            end

            # Select random card and cache it
            set total_cards (${pkgs.jq}/bin/jq '. | length' "$bulk_cache")
            set random_index (random 0 (math $total_cards - 1))
            ${pkgs.jq}/bin/jq ".[$random_index] | . + {cached_date: \"$today\"}" "$bulk_cache" > "$daily_card"
          end

          # Read cached card (fast!)
          set card (cat "$daily_card")
          set name (echo $card | ${pkgs.jq}/bin/jq -r '.name')
          set mana_cost (echo $card | ${pkgs.jq}/bin/jq -r '.mana_cost // "N/A"')
          set type_line (echo $card | ${pkgs.jq}/bin/jq -r '.type_line')
          set oracle_text (echo $card | ${pkgs.jq}/bin/jq -r '.oracle_text // "No text"')
          set set_name (echo $card | ${pkgs.jq}/bin/jq -r '.set_name')
          set rarity (echo $card | ${pkgs.jq}/bin/jq -r '.rarity')

          echo "╔════════════════════════════════════════╗"
          echo "║      Random MTG Card of the Day        ║"
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
