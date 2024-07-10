{ config, pkgs, ... }:

{
  environment.systemPackages = [
    motd
  ];
  programs.bash.interactiveShellInit = ''
    motd
  '';
}
