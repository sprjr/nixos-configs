{ config, lib, pkgs, nvidia-patch, nixpkgs, ... }:

{
  # Reference:
  # https://nixos.wiki/wiki/Nvidia

  # Also, an input (nvidia-patch) has been added to the flake.nix inputs

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load Nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];
  nixpkgs.overlays = [inputs.nvidia-patch.overlays.default]; # github.com/icewind1991/nvidia-patch-nixos

  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    open = true;
    nvidiaSettings = true; # Nvidia Settings menu. Active with `nvidia-settings`.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
