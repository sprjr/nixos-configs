{ config, pkgs, home-manager, ... }:

{
  # Modules
  imports = [
    ./modules/user-space/zellij/zellij-layout.nix
    ./modules/user-space/zellij/zellij-config.nix
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "sprjr";
    userEmail = "patrick@rawlinson.ws";
  };

  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      ale
      nord-vim
      vim-airline
      vim-airline-themes
      vim-better-whitespace
    ];
    extraConfig = ''
      syntax on

      " Turn on line numbers
      set number

      " Enable better whitespace
      let g:better_whitespace_enabled=1
      augroup vimrc
          autocmd TermOpen * :DisableWhitespace
      augroup END

      " Spell check in markdown files
      autocmd FileType markdown setlocal spell spelllang=en_us

      " https://github.com/dense-analysis/ale/blob/master/supported-tools.md
      " External dependencies
      " REMINDER TO SELF: don't use cspell (has some annoying defaults)
      " ALE nix syntax highlighting
      let $PATH = "${pkgs.nixfmt-rfc-style}/bin:" . $PATH
      " shellcheck syntax highlighting
      let $PATH = "${pkgs.shellcheck}/bin:" . $PATH
      " Vim syntax highlighting
      let $PATH = "${pkgs.vim-vint}/bin:" . $PATH

      " Ale-hover
      let g:ale_floating_preview = 1
      let g:ale_floating_window_border = []
      let g:ale_hover_to_floating_preview = 1
      let g:ale_detail_to_floating_preview = 1
      let g:ale_echo_cursor = 1

      " Fix for hover: https://github.com/dense-analysis/ale/issues/4424#issuecomment-1397609473
      let g:ale_virtualtext_cursor = 'disabled'
    '';
  };

  # .bashrc configuration
  programs = {
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
	gomuks = "docker run -e TERM=xterm -it --rm heywoodlh/gomuks";
	kubectl = "k3s kubectl";
        ls = "lsd -l";
	tf = "terraform";
	weather = "curl -s v2.wttr.in/saratoga+springs+utah";
	yt-dl = "nix-shell -p yt-dlp";
      };
    };
    zsh = {
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
	gomuks = "docker run -e TERM=xterm -it --rm heywoodlh/gomuks";
	kubectl = "k3s kubectl";
        ls = "lsd -l";
	tf = "terraform";
	weather = "curl -s v2.wttr.in/saratoga+springs+utah";
	yt-dl = "nix-shell -p yt-dlp";
      };
    };
  };

  programs.starship = {
    enable = true;
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

  home.stateVersion = "24.05";
}
