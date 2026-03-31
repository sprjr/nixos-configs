{ config, pkgs, home-manager, ... }:

{
  home.file.".config/helix/config.toml" = {
    text = ''
      theme = "nord"

      [editor]
      line-number = "absolute"
      render-whitespace = "trailing"

      [editor.whitespace.characters]
      space    = " "
      tab      = "→"
      newline  = " "
      tabpad   = " "

      [editor.hover]
      auto-popup = true
    '';
  };
}
