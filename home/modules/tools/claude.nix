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
        "Read(/**)"
        "Edit(/**)"
        "Write(/**)"
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
