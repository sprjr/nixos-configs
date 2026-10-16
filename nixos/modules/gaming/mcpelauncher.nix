{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mcpelauncher-ui-qt
  ];
}
