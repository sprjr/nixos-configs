{
  config,
  pkgs,
  lib,
  ...
}:

# Temporary: new badgey hardware before cutover. Base system only; stateful
# services (hermes, frigate, ha-events) stay on old badgey until cutover.
{
  imports = [ ../../modules/system/sops.nix ];

  networking.hostName = "badgey-next";

  homelab.netbird-client.setupKey = "netbird/setup-key-servers";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    # Prebuilt ollama-cuda; cache.nixos.org does not carry unfree CUDA builds
    extra-substituters = [ "https://cache.nixos-cuda.org" ];
    extra-trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
  };
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  services.ollama.package = pkgs.ollama-cuda;

  nix = {
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 21d";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    duf
    wget
    htop
    nvtopPackages.nvidia
    cryptsetup
    tpm2-tools
    btrfs-progs
    compsize
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

  system.stateVersion = "25.11";
}
