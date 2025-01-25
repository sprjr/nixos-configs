{ config, pkgs, home-manager, ... }:

{
  home.file.".config/bat/config" = {
    text = ''
      # Run `bat --list-themes` for a list of all available themes
       --theme="Nord"

       # Show line numbers, git modifications, and file header (no grid)
       --style="numbers,changes,header"

       # Enable this to use italic text on the terminal. This is not supported on all terminal emulators (like tmux, by default)
       --italic-text=always
    '';
  };
}
