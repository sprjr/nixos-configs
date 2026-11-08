{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ../../modules/system/sops.nix ];

  services.hermes-fileshare.enable = true;
  services.frigate-analyzer = {
    enable = true;
    # Needs frigate/control-token in sops-nix/sops.yaml
    remoteControl.enable = true;
  };

  networking.hostName = "badgey";

  homelab.netbird-client.setupKey = "netbird/setup-key-servers";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
      rocmPackages.clr.icd
    ];
  };

  nix = {
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 21d";
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    duf
    wget
    amdtop
    htop
    cryptsetup
    tpm2-tools
    btrfs-progs
    compsize
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
    sops
  ];

  services.tailscale.enable = true;

  services.unit-failure-notify = {
    enable = true;
    ntfyUrlFile = config.sops.secrets."monitoring/ntfy/comin-url".path;
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  homelab.winTest = {
    enable = true;
    isoPath = "/var/lib/libvirt/isos/win11.iso";
    firmwareFeatures = [ ];
    tpm = false;
  };

  system.stateVersion = "25.11";
}
