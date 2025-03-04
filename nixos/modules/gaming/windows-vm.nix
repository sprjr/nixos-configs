let
  # AMD 5700 XT
  gpuIDs = [
    "1002:731f" # GPU
    "1022:1487" # Matisse Audio Controller
  ];

in { pkgs, lib, config, ... }:

{
  options.vfio.enable = with lib;
    mkEnableOption "Configure the machine for VFIO";

  config = let cfg = config.vfio;
  in {
    boot = {
      initrd.kernelModules = [
        "vfio_pci"
	"vfio"
	"vfio_iommu_type1"
#"vfio_virqfd"

	"amdgpu"
	"kvm_amd"
      ];

      kernelParams = [
      # enable IOMMU
      "amd_iommu=on"
    ] ++ lib.optional cfg.enable
      # isolate the GPU
      ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs);
    };

    hardware.graphics.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
