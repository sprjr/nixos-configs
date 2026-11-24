{ config, pkgs, lib, ... }:

{
  users.groups.ansible = { };

  users.users.patrick.extraGroups = [ "ansible" ];

  security.sudo.extraRules = [
    {
      groups = [ "ansible" ];
      commands = [
        { command = "ALL"; options = [ "NOPASSWD" "SETENV" ]; }
      ];
    }
  ];

  environment.systemPackages = [ pkgs.python3 ];
}
