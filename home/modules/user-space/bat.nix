{ ... }:

{
  # Theme is provided by Stylix (programs.bat.config.theme = "base16-stylix").
  # Only non-theming flags are declared here.
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      italic-text = "always";
    };
  };
}
