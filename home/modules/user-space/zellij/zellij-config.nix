{ ... }:

{
  imports = [ ./zellij-layout-remote.nix ];

  # Palette comes from Stylix (programs.zellij.themes.stylix); Stylix defines the
  # theme but does not select it, so name it here.
  programs.zellij = {
    enable = true;
    settings = {
      show_startup_tips = false;
      theme = "stylix";
    };
  };
}
