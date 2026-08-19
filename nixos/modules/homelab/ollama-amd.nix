{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.ollama = {
    package = pkgs.ollama-rocm;
    enable = true;
    host = "0.0.0.0";
    loadModels = [
      "qwen3:8b"
      "qwen3.5:4b"
      "deepseek-r1:7b"
      "gemma4:4b"
      "hf.co/unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF"
      "hf.co/Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-GGUF"
    ];
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_GPU = "999";
      OLLAMA_NEW_ENGINE = "1";
      # Navi 10 (gfx1010) — verified with rocminfo
      HSA_OVERRIDE_GFX_VERSION = "10.1.0";
    };
  };

  networking.firewall.allowedTCPPorts = [ 11434 ];
}
