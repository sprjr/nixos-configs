{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.ollama = {
    package = pkgs.ollama-cuda;
    enable = false;
    host = "0.0.0.0";
    loadModels = [
      "qwen3.5:35b"
      "qwen3.5:9b"
    ];
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_GPU = "999";
      OLLAMA_GPU_OVERHEAD = "0";
      OLLAMA_NEW_ENGINE = "1";
      CUDA_VISIBLE_DEVICES = "0";
    };
  };
}
