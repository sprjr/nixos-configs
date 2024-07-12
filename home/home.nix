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
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      . ~/oldbashrc
    '';
  };
  home.stateVersion = "23.11";
}
