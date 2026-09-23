{
  config,
  pkgs,
  ...
}:

{
  # Theme comes from Stylix (programs.helix.settings.theme = "stylix").
  programs.helix.settings = {
    editor = {
      line-number = "absolute";
      soft-wrap = {
        enable = true;
        wrap-at-text-width = true;
      };
      whitespace = {
        render = {
          space = "none";
          tab = "all";
          newline = "none";
        };
        characters = {
          space = " ";
          tab = "→";
          newline = " ";
          tabpad = " ";
        };
      };
      lsp = {
        auto-signature-help = true;
        display-inlay-hints = false;
      };
    };
  };
}
