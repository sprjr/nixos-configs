{
  config,
  pkgs,
  ...
}:

{
  programs.helix.settings = {
    theme = "catppuccin_mocha";
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
