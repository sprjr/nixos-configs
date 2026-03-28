{ config, pkgs, lib, dark-wallpaper-laptop, nixos-cosmic, cosmic-applets, configRoot, ... }:

with lib;

let
  cfg = config.patrick.home.cosmic;
  cosmicDir = "${config.home.homeDirectory}/.config/cosmic";

  cosmicFiles = {
    "com.system76.CosmicComp/v1/active_hint" = "false";
    "com.system76.CosmicComp/v1/autotile" = "true";
    "com.system76.CosmicComp/v1/autotile_behavior" = "PerWorkspace";
    "com.system76.CosmicComp/v1/input_touchpad" = ''
      (
          state: Enabled,
          acceleration: Some((
              profile: Some(Adaptive),
              speed: 0.03853627492575307,
          )),
          click_method: Some(Clickfinger),
          disable_while_typing: Some(false),
          scroll_config: Some((
              method: Some(TwoFinger),
              natural_scroll: Some(true),
              scroll_button: None,
              scroll_factor: None,
          )),
          tap_config: Some((
              enabled: true,
              button_map: Some(LeftRightMiddle),
              drag: true,
              drag_lock: false,
          )),
      )'';
    "com.system76.CosmicComp/v1/workspaces" = ''
      (
          workspace_mode: OutputBound,
          workspace_layout: Horizontal,
      )'';
    "com.system76.CosmicComp/v1/xkb_config" = ''
      (
          rules: "",
          model: "pc104",
          layout: "",
          variant: "",
          options: Some("terminate:ctrl_alt_bksp,lv3:ralt_switch"),
          repeat_delay: 300,
          repeat_rate: 35,
      )'';
    "com.system76.CosmicSettings.Shortcuts/v1/custom" = ''
      {
          (
              modifiers: [
                  Super,
              ],
              key: "semicolon",
          ): ToggleSticky,
      }'';
    "com.system76.CosmicPanel.Dock/v1/anchor" = "Bottom";
    "com.system76.CosmicPanel.Dock/v1/anchor_gap" = "false";
    "com.system76.CosmicPanel.Dock/v1/autohide" = ''
      Some((
          wait_time: 500,
          transition_time: 200,
          handle_size: 2,
          unhide_delay: 200,
      ))'';
    "com.system76.CosmicPanel.Dock/v1/autohover_delay_ms" = "Some(500)";
    "com.system76.CosmicPanel.Dock/v1/border_radius" = "0";
    "com.system76.CosmicPanel.Dock/v1/exclusive_zone" = "false";
    "com.system76.CosmicPanel.Dock/v1/expand_to_edges" = "false";
    "com.system76.CosmicPanel.Dock/v1/keyboard_interactivity" = "OnDemand";
    "com.system76.CosmicPanel.Dock/v1/layer" = "Top";
    "com.system76.CosmicPanel.Dock/v1/margin" = "0";
    "com.system76.CosmicPanel.Dock/v1/name" = ''"Dock"'';
    "com.system76.CosmicPanel.Dock/v1/opacity" = "1.0";
    "com.system76.CosmicPanel.Dock/v1/output" = "All";
    "com.system76.CosmicPanel.Dock/v1/padding" = "0";
    "com.system76.CosmicPanel.Dock/v1/padding_overlap" = "0.5";
    "com.system76.CosmicPanel.Dock/v1/plugins_center" = "Some([])";
    "com.system76.CosmicPanel.Dock/v1/plugins_wings" = "None";
    "com.system76.CosmicPanel.Dock/v1/size" = "L";
    "com.system76.CosmicPanel.Dock/v1/size_center" = "None";
    "com.system76.CosmicPanel.Dock/v1/size_wings" = "None";
    "com.system76.CosmicPanel.Dock/v1/spacing" = "4";
    "com.system76.CosmicPanel.Panel/v1/anchor" = "Top";
    "com.system76.CosmicPanel.Panel/v1/anchor_gap" = "false";
    "com.system76.CosmicPanel.Panel/v1/autohide" = "None";
    "com.system76.CosmicPanel.Panel/v1/autohover_delay_ms" = "Some(500)";
    "com.system76.CosmicPanel.Panel/v1/border_radius" = "0";
    "com.system76.CosmicPanel.Panel/v1/exclusive_zone" = "true";
    "com.system76.CosmicPanel.Panel/v1/expand_to_edges" = "true";
    "com.system76.CosmicPanel.Panel/v1/keyboard_interactivity" = "OnDemand";
    "com.system76.CosmicPanel.Panel/v1/layer" = "Top";
    "com.system76.CosmicPanel.Panel/v1/margin" = "0";
    "com.system76.CosmicPanel.Panel/v1/name" = ''"Panel"'';
    "com.system76.CosmicPanel.Panel/v1/opacity" = "0.0";
    "com.system76.CosmicPanel.Panel/v1/output" = "All";
    "com.system76.CosmicPanel.Panel/v1/padding" = "0";
    "com.system76.CosmicPanel.Panel/v1/plugins_center" = ''
      Some([
          "com.system76.CosmicAppletTime"
      ])'';
    "com.system76.CosmicPanel.Panel/v1/plugins_wings" = ''
      Some(([], [
          "com.system76.CosmicAppletInputSources",
          "com.system76.CosmicAppletStatusArea",
          "com.system76.CosmicAppletTiling",
          "com.system76.CosmicAppletAudio",
          "com.system76.CosmicAppletBluetooth",
          "com.system76.CosmicAppletNetwork",
          "com.system76.CosmicAppletBattery",
          "com.system76.CosmicAppletNotifications",
          "com.system76.CosmicAppletPower",
      ]))'';
    "com.system76.CosmicPanel.Panel/v1/size" = "XS";
    "com.system76.CosmicPanel.Panel/v1/size_center" = "None";
    "com.system76.CosmicPanel.Panel/v1/size_wings" = "None";
    "com.system76.CosmicPanel.Panel/v1/spacing" = "4";
    "com.system76.CosmicAppletAudio/v1/show_media_controls_in_top_panel" = "true";
    "com.system76.CosmicAppletTime/v1/first_day_of_week" = "6";
    "com.system76.CosmicAppletTime/v1/military_time" = "true";
    "com.system76.CosmicAppletTime/v1/show_seconds" = "true";
    "com.system76.CosmicAppList/v1/enable_drag_source" = "true";
    "com.system76.CosmicAppList/v1/favorites" = ''
      [
          "com.mitchellh.ghostty",
          "firefox",
          "com.system76.CosmicFiles",
      ]'';
    "com.system76.CosmicAppList/v1/filter_top_levels" = "None";
    "com.system76.CosmicBackground/v1/same-on-all" = "true";
    "com.system76.CosmicPanel/v1/entries" = ''
      [
          "Panel",
          "Dock",
      ]'';
    "com.system76.CosmicTheme.Dark/v1/control_tint" = ''
      Some((
          red: 0.46666667,
          green: 0.46666667,
          blue: 0.46666667,
      ))'';
    "com.system76.CosmicTheme.Dark/v1/corner_radii" = ''
      (
          radius_0: (0.0, 0.0, 0.0, 0.0),
          radius_xs: (2.0, 2.0, 2.0, 2.0),
          radius_s: (8.0, 8.0, 8.0, 8.0),
          radius_m: (8.0, 8.0, 8.0, 8.0),
          radius_l: (8.0, 8.0, 8.0, 8.0),
          radius_xl: (8.0, 8.0, 8.0, 8.0),
      )'';
    "com.system76.CosmicTheme.Dark/v1/is_dark" = "true";
    "com.system76.CosmicTheme.Dark/v1/is_frosted" = "true";
    "com.system76.CosmicTheme.Dark/v1/name" = ''"cosmic-dark"'';
    "com.system76.CosmicTheme.Dark/v1/shade" = ''
      (
          red: 0.0,
          green: 0.0,
          blue: 0.0,
          alpha: 0.32,
      )'';
    "com.system76.CosmicTheme.Dark/v1/spacing" = ''
      (
          space_none: 4,
          space_xxxs: 8,
          space_xxs: 12,
          space_xs: 16,
          space_s: 24,
          space_m: 32,
          space_l: 48,
          space_xl: 64,
          space_xxl: 128,
          space_xxxl: 160,
      )'';
    "com.system76.CosmicTheme.Dark/v1/window_hint" = "None";
    "com.system76.CosmicTheme.Mode/v1/is_dark" = "true";
    "com.system76.CosmicTk/v1/header_size" = "Spacious";
    "com.system76.CosmicTk/v1/icon_theme" = ''"Cosmic"'';
    "com.system76.CosmicTk/v1/interface_density" = "Spacious";
    "com.system76.CosmicTk/v1/interface_font" = ''
      (
          family: "JetBrainsMono Nerd Font",
          weight: Normal,
          stretch: Normal,
          style: Normal,
      )'';
    "com.system76.CosmicTk/v1/monospace_font" = ''
      (
          family: "JetBrainsMonoNL Nerd Font Mono",
          weight: Normal,
          stretch: Normal,
          style: Normal,
      )'';
  };

  wallpaperFile = {
    "com.system76.CosmicBackground/v1/all" = pkgs.writeText "cosmic-background-all" ''
      (
          output: "all",
          source: Path("${dark-wallpaper-laptop}"),
          filter_by_theme: true,
          rotation_frequency: 300,
          filter_method: Lanczos,
          scaling_mode: Fit((0.0, 0.0, 0.0)),
          sampling_method: Alphanumeric,
      )'';
  };

  writeStaticFiles = concatStringsSep "\n" (mapAttrsToList (path: content:
    "install -Dm644 ${pkgs.writeText "cosmic-${baseNameOf path}" content} ${cosmicDir}/${path}"
  ) cosmicFiles);

  writeWallpaperFiles = concatStringsSep "\n" (mapAttrsToList (path: storePath:
    "install -Dm644 ${storePath} ${cosmicDir}/${path}"
  ) wallpaperFile);
in
{
  imports = [ nixos-cosmic.nixosModules.default ];

  nixpkgs.overlays = [
    nixos-cosmic.overlays.default
    (final: prev: {
      cosmic-edit = prev.cosmic-edit.overrideAttrs (_: {
        src = prev.fetchFromGitHub {
          owner = "pop-os";
          repo = "cosmic-edit";
          rev = prev.cosmic-edit.src.rev;
          hash = "sha256-GN1Zts+v3ARcrkN+ZkMUSGNOAlIhXSYWRtWAyqUfUrY=";
        };
      });
    })
  ];

  nix.settings = {
    substituters = [ "https://cosmic.cachix.org" ];
    trusted-public-keys = [ "cosmic.cachix.org-1:Dya6IxT5r5k6SJOsGKFGMEMQDcWlBoAN1JgaoL/hMKE=" ];
  };
}
