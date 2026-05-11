{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.ollama = {
    package = pkgs.ollama-cuda;
    enable = true;
    loadModels = [
      "qwen3.5:35b"
      "qwen3.5:9b"
    ];
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_GPU = "999";
      OLLAMA_GPU_OVERHEAD = "0";
      CUDA_VISIBLE_DEVICES = "0";
    };
  };
  systemd.services.ollama.serviceConfig = {
    Environment = [ "OLLAMA_HOST=0.0.0.0:11434" ];
  };

  environment.systemPackages = [
    (pkgs.ollama.override {
      acceleration = "cuda";
    })
  ];
}
