{ config, pkgs, home-manager, ... }:

{
  # .bashrc configuration
  programs = {
    # Enable Starship
    starship.enable = true;
    # Bash/Starship
    bash = {
      enable = true;
      # Terminal startup tasks
     #bashrcExtra = ''
     #'';
      # Aliases
      shellAliases = {
	bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
 	cat = "bat";
	compose2nix-start = "nix shell github:aksiksi/compose2nix";
	df = "duf";
	dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
	dockername = "docker inspect --format='{{.Name}}' $(sudo docker ps -aq --no-trunc)";
	kubectl = "k3s kubectl";
        ls = "lsd -l";
	weather = "curl -s v2.wttr.in/saratoga+springs+utah";
	yt-dl = "nix-shell -p yt-dlp";
      };
    };
    zsh = {
      enable = true;
      initExtra = ''
        # Run fish if it's not already running
        if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]
        then
          exec fish -l
        fi
        export TERM=screen-256color
      '';
      # Terminal startup tasks
      # Aliases
      shellAliases = {
	bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
 	cat = "bat";
	compose2nix-start = "nix shell github:aksiksi/compose2nix";
	df = "duf";
	dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
	dockername = "docker inspect --format='{{.Name}}' $(sudo docker ps -aq --no-trunc)";
	kubectl = "k3s kubectl";
        ls = "lsd -l";
	tree = "tree -C";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
	yt-dl = "nix-shell -p yt-dlp";
      };
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # disable greeting
      '';
      # Aliases
      shellAliases = {
        bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
 	cat = "bat";
        compose2nix-start = "nix shell github:aksiksi/compose2nix";
        df = "duf";
        dfl = "du -aBm ./ 2>/dev/null | sort -nr | head -n 20";
        dockername = "docker inspect --format='{{.Name}}' $(sudo docker ps -aq --no-trunc)";
        kubectl = "k3s kubectl";
        ls = "lsd -l";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
        yt-dl = "nix-shell -p yt-dlp";
      };
    };
  };
}
