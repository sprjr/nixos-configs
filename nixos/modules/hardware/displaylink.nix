{ config, pkgs, ... }:

# DisplayLink USB video (evdi + DisplayLinkManager), Wayland-only replacement for
# videoDrivers = [ "displaylink" ]. Needs the vendor zip in the store first; the
# build error prints the nix-prefetch-url command.
let
  # nixpkgs evdi installs the .ko by hand, skipping kmodigest signing, so module
  # aggregation fails on the missing evdi.ko.cer. Sign after fixup (strip drops signatures).
  evdi = config.boot.kernelPackages.evdi.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.buildPackages.kmodigest ];
    postFixup = (old.postFixup or "") + ''
      kmodigest $out/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/kernel/drivers/gpu/drm/evdi/evdi.ko
    '';
  });

  displaylink = pkgs.displaylink.override { inherit evdi; };
in
{
  boot.extraModulePackages = [ evdi ];
  boot.kernelModules = [ "evdi" ];

  services.udev.packages = [ displaylink ];

  # Suspend/resume handshake with DisplayLinkManager, from upstream module.
  powerManagement.powerDownCommands = ''
    while read -r -n 1 -t 1 < /tmp/PmMessagesPort_out; do : ; done;
    echo "S" > /tmp/PmMessagesPort_in
    if [ -f /tmp/PmMessagesPort_out ]; then
      read -r -n 1 -t 10 < /tmp/PmMessagesPort_out
    fi
  '';
  powerManagement.resumeCommands = ''
    echo "R" > /tmp/PmMessagesPort_in
  '';

  # Started by the displaylink udev rule (SYSTEMD_WANTS) when a device is plugged in.
  systemd.services.dlm = {
    description = "DisplayLink Manager Service";
    serviceConfig = {
      ExecStart = "${displaylink}/bin/DisplayLinkManager";
      Restart = "always";
      RestartSec = 5;
      LogsDirectory = "displaylink";
    };
  };
}
