{
  config,
  pkgs,
  modulesPath,
  ...
}:

let
  ntfyUrlFile = config.sops.secrets."monitoring/ntfy/comin-url".path;
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  networking.hostName = "ds9";

  # Linode: BIOS GRUB on the disko-managed disk, LISH serial console
  boot.loader.grub.enable = true;
  boot.loader.timeout = 10;
  boot.kernelParams = [ "console=ttyS0,19200n8" ];
  boot.loader.grub.extraConfig = ''
    serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
    terminal_input serial;
    terminal_output serial
  '';

  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.firewall.enable = true;

  # SSH over the tailnet only; LISH is the fallback
  services.openssh.openFirewall = false;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  services.tailscale.enable = true;

  # Host-only age key; the primary key is never placed on this machine
  sops = {
    defaultSopsFile = ../../../sops-nix/relay.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets."ds9/patrick-password-hash".neededForUsers = true;
  };

  users.users.patrick.hashedPasswordFile = config.sops.secrets."ds9/patrick-password-hash".path;

  services.unit-failure-notify = {
    enable = true;
    inherit ntfyUrlFile;
  };

  systemd.services.boot-notify = {
    description = "Send ntfy notification after boot";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "tailscaled.service"
      "ntfy-sh.service"
    ];
    wants = [ "network-online.target" ];
    path = [ pkgs.ntfy-sh ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 30;
    };
    script = ''
      ntfy publish --title "${config.networking.hostName} event:" --tags electric_plug \
        "$(cat ${ntfyUrlFile})" "This device just finished booting up."
    '';
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "delete-older-than 14d";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2048;
    }
  ];

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    htop
  ];

  system.stateVersion = "25.11";
}
