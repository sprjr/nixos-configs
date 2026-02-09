{ config, pkgs, ... }:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@rawlinson.xyz";

    certs."talk.rawlinson.xyz" = {
      group = "mumble";
      webroot = null;
    };
  };

  # create mumble group to manage file access
  users.groups.mumble = {};

  systemd.timers.acme-mumble-rawlinson-xyz.wantedBy = [ "timers.target" ];
}
