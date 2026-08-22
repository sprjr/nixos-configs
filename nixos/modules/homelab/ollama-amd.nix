{
  config,
  pkgs,
  lib,
  ...
}:

let
  warmupModel = "qwen3.5:4b";
  warmupScript = pkgs.writeShellScript "ollama-warmup" ''
    for i in $(seq 1 30); do
      if curl -sf http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
        echo "Ollama API ready, loading ${warmupModel} into VRAM"
        if curl -sf -X POST http://127.0.0.1:11434/api/chat \
          -H "Content-Type: application/json" \
          -d '{"model":"${warmupModel}","messages":[{"role":"user","content":"ping"}],"stream":false,"keep_alive":-1}' \
          > /dev/null 2>&1; then
          echo "${warmupModel} loaded and pinned in VRAM"
          exit 0
        else
          echo "Failed to load ${warmupModel}"
          exit 1
        fi
      fi
      sleep 2
    done
    echo "Ollama API did not become ready within 60s"
    exit 1
  '';
in
{
  services.ollama = {
    package = pkgs.ollama-rocm;
    enable = true;
    host = "0.0.0.0";
    loadModels = [
      "hermes3:8b"
      "qwen3:8b"
      "qwen3.5:4b"
      "deepseek-r1:7b"
      "gemma3:4b"
      "moondream:1.8b"
      "hf.co/unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF"
      "hf.co/Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-GGUF"
    ];
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_GPU = "999";
      OLLAMA_NEW_ENGINE = "1";
      OLLAMA_CONTEXT_LENGTH = "16384";
      # Navi 10 (gfx1010) — verified with rocminfo
      HSA_OVERRIDE_GFX_VERSION = "10.1.0";
    };
  };

  systemd.services.ollama-model-warmup = {
    description = "Load qwen3.5:4b into VRAM with keep_alive=-1";
    after = [ "ollama.service" ];
    requires = [ "ollama.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.curl ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${warmupScript}";
    };
  };

  networking.firewall.allowedTCPPorts = [ 11434 ];
}
