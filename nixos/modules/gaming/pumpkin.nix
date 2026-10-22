{ ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      pumpkin = prev.pumpkin.overrideAttrs (old: {
        env = (old.env or { }) // {
          RUST_MIN_STACK = "33554432";
        };
      });
    })
  ];

  services.pumpkin = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 25565 ];
}
