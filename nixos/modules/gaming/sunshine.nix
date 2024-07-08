# Run `sunshine &` to start
{ config, pkgs, ... }:

{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      47984
      47989
      47990
      48010
    ];

    allowedUDPPorts = [
      #{ from = 47998; to = 48000; }
      47998
      47999
      48000
    ];
  };

  services.sunshine = {
    enable = true;
    settings = {
      port = 47989;
    };
    capSysAdmin = true;
    openFirewall = true;
    autoStart = true;
  };
}
