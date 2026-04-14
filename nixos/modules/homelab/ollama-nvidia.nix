{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.ollama = {
    package = pkgs.ollama;
    enable = true;
    loadModels = [
      "qwen3.5:35b"
      "qwen3.5:9b"
    ];
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
