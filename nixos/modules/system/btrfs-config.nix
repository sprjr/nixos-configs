{ pkgs, ... }:
{
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.availableKernelModules = [
    "tpm_tis"
    "tpm_crb"
  ];

  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize
    cryptsetup
    tpm2-tools
  ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  systemd.services.tpm2-luks-enroll = {
    description = "Auto-enroll TPM2 for LUKS unlock on first boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "!/var/lib/tpm2-luks-enrolled";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "journal";
      StandardError = "journal";
    };
    path = with pkgs; [
      tpm2-tools
      cryptsetup
      systemd
      util-linux
      gawk
      coreutils
    ];
    script = ''
      set -euo pipefail

      LUKS_DEVICE=$(lsblk -o NAME,FSTYPE -lpn | awk '$2 == "crypto_LUKS" { print $1; exit }')
      if [ -z "$LUKS_DEVICE" ]; then
        echo "ERROR: no LUKS device found via lsblk" >&2
        exit 1
      fi
      echo "Found LUKS device: $LUKS_DEVICE"

      if [ ! -e /dev/tpmrm0 ] && [ ! -e /dev/tpm0 ]; then
        echo "ERROR: no TPM2 device node (/dev/tpm0 or /dev/tpmrm0) — verify TPM is enabled in firmware" >&2
        exit 1
      fi

      if [ ! -f /var/lib/secrets/luks.key ]; then
        echo "ERROR: no keyfile at /var/lib/secrets/luks.key — push it via --extra-files at deploy time" >&2
        exit 1
      fi

      echo "Enrolling TPM2 (PCRs 0+2+7+12) against $LUKS_DEVICE..."
      systemd-cryptenroll \
        --tpm2-device=auto \
        --tpm2-pcrs=0+2+7+12 \
        --unlock-key-file=/var/lib/secrets/luks.key \
        "$LUKS_DEVICE"

      shred -u /var/lib/secrets/luks.key 2>/dev/null || rm -f /var/lib/secrets/luks.key
      touch /var/lib/tpm2-luks-enrolled
      echo "TPM2 auto-enrollment complete"
    '';
  };
}
