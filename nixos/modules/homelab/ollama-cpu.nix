{ config, pkgs, lib, ... }:

{
  services.ollama = {
    package = pkgs.ollama;
    enable = true;
    loadModels = [
      "codegemma"
      "codellama:34b"
      "codestral:22b"
      "deepseek-coder-v2"
      "deepseek-r1"
      "gemma3:4b"
      "llama3.2-vision:11b"
    ];
  };

  # Handle pgvector throwing errors on build
  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages // {
        pgvector = prev.python3Packages.pgvector.overrideAttrs (old: {
	  doCheck = false;
	});
      };
    })
  ];

  systemd.services.ollama.serviceConfig = {
    Environment = [ "OLLAMA_HOST=0.0.0.0:11434" ];
  };

  services.open-webui = {
    enable = true;
    port = 31131;
    host = "0.0.0.0";
    environment = {
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
    };
  };

  environment.systemPackages = with pkgs; [
    oterm
  ];
}
