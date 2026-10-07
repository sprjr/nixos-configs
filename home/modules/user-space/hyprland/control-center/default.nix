{
  config,
  pkgs,
  lib,
  ags,
  osConfig ? { },
  ...
}:

with lib;

let
  cfg = config.patrick.home.hyprland;
  c = config.lib.stylix.colors.withHashtag;
  data = import ../keybind-data.nix { inherit pkgs; };

  isLaptop = cfg.formFactor == "laptop";

  # Host features the widgets can't detect themselves.
  features = builtins.toJSON {
    comin = osConfig.services.comin.enable or false;
  };

  agsConfig = pkgs.stdenv.mkDerivation {
    name = "ags-control-center-config";
    src = ./config;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
      cat > $out/vars.css << 'VARS'
      :root {
        --bg: ${c.base00};
        --bg-alt: ${c.base01};
        --bg-hover: ${c.base02};
        --fg: ${c.base05};
        --fg-dim: ${c.base04};
        --accent: ${c.base0D};
        --green: ${c.base0B};
        --yellow: ${c.base0A};
        --red: ${c.base08};
        --orange: ${c.base09};
        --cyan: ${c.base0C};
        --purple: ${c.base0E};
        --border: ${c.base03};
        --radius: 12px;
        --panel-width: 400px;
        --is-laptop: ${if isLaptop then "1" else "0"};
      }
      VARS
      cat > $out/features.json << 'FEATURES'
      ${features}
      FEATURES
      cp ${data.ts} $out/keybind-data.ts
    '';
  };

  toggleScript = pkgs.writeShellApplication {
    name = "control-center-toggle";
    text = ''ags request "toggle"'';
  };

  hwToggleScript = pkgs.writeShellApplication {
    name = "hw-monitor-toggle";
    text = ''ags request "toggle-hw"'';
  };

  keybindsToggleScript = pkgs.writeShellApplication {
    name = "keybinds-toggle";
    text = ''ags request "toggle-keybinds"'';
  };
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    programs.ags = {
      enable = true;
      configDir = agsConfig;
      systemd.enable = true;
      extraPackages =
        (with ags.packages.${pkgs.system}; [
          io
          astal4
          network
          bluetooth
          wireplumber
          battery
          powerprofiles
          mpris
          hyprland
        ])
        ++ [ pkgs.libadwaita ];
    };

    home.packages = [
      toggleScript
      hwToggleScript
      keybindsToggleScript
      pkgs.brightnessctl
    ];

    systemd.user.services.ags = {
      Install.WantedBy = mkForce [ "hyprland-session.target" ];
      # ags bundles the config at startup; a config change must restart the running instance.
      Unit.X-Restart-Triggers = [ "${agsConfig}" ];
    };

    wayland.windowManager.hyprland.settings = {
      "layerrule[control-center]" = {
        "match:namespace" = "^(control-center)$";
        blur = 1;
        ignore_alpha = 0.0;
        animation = "slide right";
      };
      "layerrule[hw-monitor]" = {
        "match:namespace" = "^(hw-monitor)$";
        blur = 1;
        ignore_alpha = 0.0;
        animation = "slide right";
      };
      "layerrule[keybinds]" = {
        "match:namespace" = "^(keybinds)$";
        blur = 1;
        ignore_alpha = 0.0;
        animation = "slide right";
      };
    };
  };
}
