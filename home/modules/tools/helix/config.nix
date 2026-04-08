{
  config,
  pkgs,
  home-manager,
  ...
}:

{
  home.file.".config/helix/config.toml" = {
    text = ''
      theme = "nord"

      [editor]
      line-number = "absolute"

      [editor.softwrap]
      enable = true

      [editor.whitespace]
      render = { space = "none", tab = "all", newline = "none" }

      [editor.whitespace.characters]
      space    = " "
      tab      = "→"
      newline  = " "
      tabpad   = " "

      [editor.lsp]
      auto-signature-help = true
      display-inlay-hints = false
    '';
  };
}
