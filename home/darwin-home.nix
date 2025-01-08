{ config, pkgs, home-manager, ... }:

{
  # Modules
  imports = [
    ./modules/user-space/zellij/zellij-layout-darwin.nix
    ./modules/user-space/zellij/zellij-config.nix
    ./modules/tools/neovim.nix
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "sprjr";
    userEmail = "patrick@rawlinson.ws";
  };

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
    zsh = {
      enable = true;
      initExtra = ''
        if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]
        then
          exec fish -l
        fi
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
	weather = "curl -s v2.wttr.in/saratoga+springs+utah";
	yt-dl = "nix-shell -p yt-dlp";
      };
    };
  };

  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/patrick" else "/home/patrick";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Home-manager packages
  home.packages = with pkgs; [
    # Global packages
    bat
    docker
    docker-compose
    duf
    glow
    htop
    lima # VMs/Docker
    lsd
    mtr
    syncthing
    tldr
    zellij
  ] ++ lib.optionals stdenv.isLinux [
    # Linux-specific packages
    anki
    firefox
    libvirt
  ] ++ lib.optionals stdenv.isDarwin [
    # MacOS-specific packages
    mas
    m-cli
    pinentry_mac
  ];

  # Ghostty configuration
  home.file.".config/ghostty/config" = {
    text = ''
      font-family = ""
      font-family = "JetBrains Mono"
      theme = nord
      bold-is-bright = true
      background-opacity = 0.7
      background-blur-radius = 20
      macos-titlebar-style = hidden
      initial-command = export TERM=screen-256color
      command = zellij --layout=.config/zellij/layouts/darwin.kdl
      # https://github.com/ghostty-org/ghostty/pull/3742
      # quick-terminal-size = 80%

      # quake mode; on MacOS give Ghostty accessibility permissions
      keybind = global:ctrl+grave_accent=toggle_quick_terminal
      quick-terminal-animation-duration = 0.2
    '';
  };

  home.stateVersion = "24.05";
}
