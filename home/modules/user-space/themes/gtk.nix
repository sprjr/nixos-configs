{ pkgs, config, ... }:

{
  # Theme, colours, fonts, and icons all come from Stylix. The Qt platform theme is
  # Stylix's too (qtct), so nothing but the Qt bridge is declared here.
  qt.enable = true;
}
