{ config, pkgs, home-manager, ... }:

{
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
      vim-airline
      vim-airline-themes
      vim-better-whitespace
      nord-vim
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
    '';
  };

  # .bashrc configuration
  programs = {
    # Bash/Starship
    bash = {
      enable = true;
      # Terminal startup tasks
      bashrcExtra = ''
        hyfetch
      '';
      # Aliases
      shellAliases = {
        ls = "lsd -l";
        cat = "bat";
        df = "duf";
        gomuks = "docker run -e TERM=xterm -it --rm heywoodlh/gomuks";
        kubectl = "k3s kubectl";
        compose2nix-start = "nix shell github:aksiksi/compose2nix";
        yt-dl = "nix-shell -p yt-dlp";
        weather = "curl -s v2.wttr.in/saratoga+springs+utah";
        bf = "du -aBm / 2>/dev/null | sort -nr | head -n 20";
      };
    };
  };
  home.stateVersion = "23.11";
}
