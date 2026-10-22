{ config, ... }:

{
  sops.secrets."paperless/admin-password" = { };

  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    port = 28981;
    domain = "paperless.rawliyosh.com";
    passwordFile = config.sops.secrets."paperless/admin-password".path;
    database.createLocally = true;
    exporter.enable = true;
    settings = {
      PAPERLESS_AI_ENABLED = true;
      PAPERLESS_AI_LLM_BACKEND = "ollama";
      PAPERLESS_AI_LLM_MODEL = "qwen3.5:4b";
      PAPERLESS_AI_LLM_ENDPOINT = "http://badgey:11434";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 28981 ];
}
