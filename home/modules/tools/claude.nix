{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    claude-code
  ];

  home.file.".claude/settings.json" = {
    text = builtins.toJSON {
      permissions = {
        defaultMode = "plan";
        disableBypassPermissionsMode = true;
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
      cleanupPeriodDays = 0;
      autoUpdatesChannel = "stable";
    };
  };
}
