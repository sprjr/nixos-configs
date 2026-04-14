{
  config,
  lib,
  pkgs,
  ...
}:

let
  claudeSettings = builtins.toJSON {
    permissions = {
      defaultMode = "plan";
      disableBypassPermissionsMode = "disable";
      allow = [ ];
      ask = [
        "Read(./**)"
        "Edit(./**)"
        "Write(./**)"
        "MultiEdit(./**)"
      ];
      deny = [
        "Read(/**)"
        "Read(~/**)"
        "Edit(/**)"
        "Edit(~/**)"
        "Write(/**)"
        "Write(~/**)"
        "MultiEdit(/**)"
        "MultiEdit(~/**)"
        "Bash(*)"
        "WebFetch"
        "WebSearch"
        "TodoWrite"
        "Task"
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
