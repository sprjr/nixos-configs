{
  config,
  lib,
  pkgs,
  ...
}:

let
  claudeSettings = builtins.toJSON {
    mcpServers = {
      nixos = {
        command = "${pkgs.nix}/bin/nix";
        args = [ "run" "github:utensils/mcp-nixos" ];
      };
      ollama = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "mcp-ollama" ];
        env = {
          OLLAMA_HOST = "http://badgey:11434";
        };
      };
    };
    permissions = {
      defaultMode = "plan";
      disableBypassPermissionsMode = "disable";
      allow = [
        "Read(~/.claude/**)"
      ];
      ask = [
        "Edit(~/.claude/**)"
        "Write(~/.claude/**)"
        "Write(~/.claude/plans/**)"
        "Edit(~/.claude/plans/**)"
        "Read(./**)"
        "Edit(./**)"
        "Read(~/**)"
        "Edit(~/**)"
        "Write(./**)"
        "Write(~/**)"
        "WebFetch"
        "WebSearch"
        "TodoWrite"
        "Task"
      ];
      deny = [
        "Read(/etc/**)"
        "Edit(/etc/**)"
        "Write(/etc/**)"
        "Read(/nix/**)"
        "Edit(/nix/**)"
        "Write(/nix/**)"
        "Read(/usr/**)"
        "Edit(/usr/**)"
        "Write(/usr/**)"
        "Read(/var/**)"
        "Edit(/var/**)"
        "Write(/var/**)"
        "Read(/boot/**)"
        "Edit(/boot/**)"
        "Write(/boot/**)"
        "Read(/sys/**)"
        "Edit(/sys/**)"
        "Write(/sys/**)"
        "Bash(*)"
      ];
    };
    disableHooks = true;
    cleanupPeriodDays = 50;
    autoUpdatesChannel = "stable";
  };
in

{
  home.packages = with pkgs; [
    claude-code
  ];

  home.file.".claude/settings.json".source = pkgs.runCommand "claude-settings.json" { } ''
    ${pkgs.jq}/bin/jq '.' ${pkgs.writeText "claude-settings-raw.json" claudeSettings} > $out
  '';
}
