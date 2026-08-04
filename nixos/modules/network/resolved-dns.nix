{ ... }:

{
  networking.networkmanager.dns = "systemd-resolved";

  networking.nameservers = [
    "1.1.1.1#one.one.one.one"
    "1.0.0.1#one.one.one.one"
  ];

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "true";
      Domains = "~.";
      FallbackDNS = "1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one";
      DNSOverTLS = "opportunistic";
    };
  };
}
