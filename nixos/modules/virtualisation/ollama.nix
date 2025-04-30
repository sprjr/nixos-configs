{ config, pkgs, ... }:

{
  services.nextjs-ollama-llm-ui = {
    enable = true;
    package = pkgs.nextjs-ollama-llm-ui;
    hostname = "0.0.0.0";
    ollamaUrl = "http://100.95.41.49:11434";
    port = 3000;
  };
  services.ollama = {
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "10.1.0";
    home = "/var/lib/ollama";
    acceleration = "rocm";
    loadModels = [
      "codegemma"
      "codellama"
      "deepseek-coder-v2"
      "deepseek-r1"
      "gemma3:4b"
    ];
  };
}
