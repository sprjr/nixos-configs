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

      [keys.normal]
      # x/X: delete char (Vim) vs select line (Helix default)
      x     = "delete_char_forward"
      X     = "delete_char_backward"

      # s: delete char + insert (Vim) vs select_regex (Helix default)
      s     = "change_selection"

      # D/C/Y: operate to end of line, matching Vim behavior
      D     = ["extend_to_line_end", "delete_selection"]
      C     = ["extend_to_line_end", "change_selection"]
      Y     = ["extend_to_line_bounds", "yank", "collapse_selection"]

      # G: end of file (Vim) vs goto_line (Helix default)
      G     = "goto_file_end"

      # Preserve displaced Helix commands on Alt bindings
      "A-x" = "select_line_below"
      "A-s" = "select_regex"
      "A-g" = "goto_line"
    '';
  };
}
