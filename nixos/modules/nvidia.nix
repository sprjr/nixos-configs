{ config, pkgs, ...}: {

  hardware.graphics = {
    enable = true;
   #driSupport = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
#     rocm-opencl-icd
      rocm-opencl-runtime
    ];
  };

  # Tell Xorg/Wayland to use the Nvidia driver:
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

    # Modesetting is required for most Wayland compositors
    modesetting.enable = true;

    # Experimental Nvidia power management, can cause sleep/suspend failure
    powerManagement.enable = false;
    # Fine-grained power management, can cause the GPU to turn off. Experimental and too new for the 1050 Ti
    powerManagement.finegrained = false;

    # Enable the Nvidia settings menu
    nvidiaSettings = true;

    # Use Nvidia open source kernel module (not Nouveau). Only available on Turing/newer hardware.
    # Full list of supported GPUs is at https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    open = false;

    # Optionally, you may need to specify the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia.prime.sync.enable = true;
  environment.systemPackages = with pkgs; [
    nvidia-docker
  ];
}
