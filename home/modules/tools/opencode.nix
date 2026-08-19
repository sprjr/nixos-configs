{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentPermissions = {
    read = "allow";
    edit = "ask";
    glob = "allow";
    grep = "allow";
    list = "allow";
    bash = "ask";
    webfetch = "ask";
    websearch = "ask";
    todowrite = "ask";
    task = "ask";
    external_directory = "ask";
  };

  opencodeSettings = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    default_agent = "general";
    autoupdate = false;
    share = "disabled";
    model = "ollama/qwen3:8b";
    mcpServers = {
      nixos = {
        command = "${pkgs.nix}/bin/nix";
        args = [
          "run"
          "github:utensils/mcp-nixos"
        ];
      };
    };
    provider = {
      ollama = {
        name = "Ollama";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "http://badgey:11434/v1";
        };
        models = {
          "qwen3:8b" = {
            _launch = false;
            name = "qwen3:8b";
          };
          "qwen3.5:4b" = {
            _launch = false;
            name = "qwen3.5:4b";
          };
          "deepseek-r1:7b" = {
            _launch = false;
            name = "deepseek-r1:7b";
          };
          "gemma4:4b" = {
            _launch = false;
            name = "gemma4:4b";
          };
        };
      };
    };
    agent = {
      build = {
        permission = agentPermissions;
      };
      general = {
        permission = agentPermissions;
      };
    };
  };
in

{
  home.packages = with pkgs; [
    opencode
    opencode-desktop
  ];

  xdg.configFile."opencode/opencode.json".source = pkgs.runCommand "opencode-config.json" { } ''
    ${pkgs.jq}/bin/jq '.' ${pkgs.writeText "opencode-config-raw.json" opencodeSettings} > $out
  '';
}
