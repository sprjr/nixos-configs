# https://nixos.wiki/wiki/samba
{
  # For mount.cifs, required unless DNS is not needed
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/share/hetzner" = {
    device = "test";
    fsType = "cifs";
    options = let
      # this line prevents hanging on a network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in ["${automount_opts},credentials=/etc/nixos/hetzner-secrets"];
  };
}
