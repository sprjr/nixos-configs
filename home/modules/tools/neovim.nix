{ config, pkgs, home-manager, ... }:

{
  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      ale
      codecompanion.nvim
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
}
