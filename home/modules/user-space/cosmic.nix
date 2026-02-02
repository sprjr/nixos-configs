{ config, pkgs, lib, dark-wallpaper-laptop, ... }:

with lib;

let
  cfg = config.patrick.home.cosmic;
  homeDir = config.home.homeDirectory;
  system = pkgs.stdenv.hostPlatform.system;
in {
  options = {
    patrick.home.cosmic = mkOption {
      default = true;
      description = ''
        Load Patrick's custom Cosmic tweaks and configuration
      '';
      type = types.bool;
    };
  };

  config = mkIf cfg {
    home.packages = with pkgs; [
      # add packages here
    ];
    # add services.options here
    xdg.configFile."com.system76.CosmicComp/v1/active_hint".text = ''
      false
    '';

    xdg.configFile."com.system76.CosmicComp/v1/autotile".text = ''
      true
    '';

    xdg.configFile."com.system76.CosmicComp/v1/autotile_behavior".text = ''
      PerWorkspace
    '';

    xdg.configFile."com.system76.CosmicComp/v1/input_touchpad".text = ''
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
      )
    '';

    xdg.configFile."com.system76.CosmicComp/v1/workspaces".text = ''
      (
          workspace_mode: OutputBound,
          workspace_layout: Horizontal,
      )
    '';

    xdg.configFile."com.system76.CosmicComp/v1/xdb_config".text = ''
      (
          rules: "",
          model: "pc104",
          layout: "",
          variant: "",
          options: Some("terminate:ctrl_alt_bksp,lv3:ralt_switch"),
          repeat_delay: 300,
          repeat_rate: 35,
      )
    '';

    xdg.configFile."com.system76.CosmicSettings.Shortcuts/v1/custom".text = ''
      {
          (
              modifiers: [
                  Super,
              ],
              key: "semicolon",
          ): ToggleSticky,
      }
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/anchor".text = ''
      bottom
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/anchor_gap".text = ''
      false
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/autohide".text = ''
      Some((
          wait_time: 500,
          transition_time: 200,
          handle_size: 2,
          unhide_delay: 200,
      ))
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/autohover_delay_ms".text = ''
      Some(500)
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/border_radius".text = ''
      0
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/exclusive_zone".text = ''
      false
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/expand_to_edges".text = ''
      false
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/keyboard_interactivity".text = ''
      OnDemand
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/layer".text = ''
      Top
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/margin".text = ''
      0
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/name".text = ''
      "Dock"
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/opacity".text = ''
      1.0
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/output".text = ''
      All
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/padding".text = ''
      0
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/padding_overlap".text = ''
      0.5
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/plugins_center".text = ''
      Some([])
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/plugins_wings".text = ''
      None
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/size".text = ''
      L
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/size_center".text = ''
      None
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/size_wings".text = ''
      None
    '';

    xdg.configFile."com.system76.CosmicPanel.Dock/v1/spacing".text = ''
      4
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/anchor".text = ''
      Top
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/anchor_gap".text = ''
      false
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/autohide".text = ''
      None
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/autohover_delay_ms".text = ''
      Some(500)
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/border_radius".text = ''
      0
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/exclusive_zone".text = ''
      true
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/expand_to_edges".text = ''
      true
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/keyboard_interactivity".text = ''
      OnDemand
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/layer".text = ''
      Top
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/margin".text = ''
      0
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/name".text = ''
      "Panel"
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/opacity".text = ''
      0.0
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/output".text = ''
      All
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/padding".text = ''
      0
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/plugins_center".text = ''
      Some([
          "com.system76.CosmicAppletTime"
      ])
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/plugins_wings".text = ''
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
      ]))
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/size".text = ''
      XS
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/size_center".text = ''
      None
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/size_wings".text = ''
      None
    '';

    xdg.configFile."com.system76.CosmicPanel.Panel/v1/spacing".text = ''
      4
    '';

    xdg.configFile."com.system76.CosmicAppletAudio/v1/show_media_controls_in_top_panel".text = ''
      true
    '';
    xdg.configFile."com.system76.CosmicAppletTime/v1/first_day_of_week".text = ''
      6
    '';
    xdg.configFile."com.system76.CosmicAppletTime/v1/military_time".text = ''
      true
    '';
    xdg.configFile."com.system76.CosmicAppletTime/v1/show_seconds".text = ''
      true
    '';

    xdg.configFile."com.system76.CosmicAppList/v1/enable_drag_source".text = ''
      true
    '';
    xdg.configFile."com.system76.CosmicAppList/v1/favorites".text = ''
      [
          "com.mitchellh.ghostty",
          "firefox",
          "com.system76.CosmicFiles",
      ]
    '';

    xdg.configFile."com.system76.CosmicAppList/v1/filter_top_levels".text = ''
      None
    '';

    xdg.configFile."com.system76.CosmicBackground/v1/all".text = ''
      (
          output: "all",
          source: Path("${dark-wallpaper-laptop}"),
          filter_by_theme: true,
          rotation_frequency: 300,
          filter_method: Lanczos,
          scaling_mode: Fit((0.0, 0.0, 0.0)),
          sampling_method: Alphanumeric,
      )
    '';

    xdg.configFile."com.system76.CosmicBackground/v1/same-on-all".text = ''
      true
    '';

    xdg.configFile."com.system76.CosmicPanel/v1/entries".text = ''
      [
          "Panel",
          "Dock",
      ]
    '';

    xdg.configFile."com.system76.CosmicTheme.Dark/v1/control_tint".text = ''
      Some((
          red: 0.46666667,
          green: 0.46666667,
          blue: 0.46666667,
      ))
    '';

    xdg.configFile."com.system76.CosmicTheme.Dark/v1/corner_radii".text = ''
      (
          radius_0: (0.0, 0.0, 0.0, 0.0),
          radius_xs: (2.0, 2.0, 2.0, 2.0),
          radius_s: (8.0, 8.0, 8.0, 8.0),
          radius_m: (8.0, 8.0, 8.0, 8.0),
          radius_l: (8.0, 8.0, 8.0, 8.0),
          radius_xl: (8.0, 8.0, 8.0, 8.0),
      )
    '';

    xdg.configFile."com.system76.CosmicTheme.Dark/v1/is_dark".text = ''
      true
    '';

    xdg.configFile."com.system76.CosmicTheme.Dark/v1/is_frosted".text = ''
      false
    '';

    xdg.configFile."com.system76.CosmicTheme.Dark/v1/name".text = ''
      "cosmic-dark"
    '';

    xdg.configFile."com.system76.CosmicTheme.Dark/v1/shade".text = ''
      (
          red: 0.0,
          green: 0.0,
          blue: 0.0,
          alpha: 0.32,
      )
    '';

    xdg.configFile."com.system76.CosmicTheme.Dark/v1/spacing".text = ''
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
      )
    '';

    xdg.configFile."com.system76.CosmicTheme.Dark/v1/window_hint".text = ''
      None
    '';

    xdg.configFile."com.system76.CosmicTheme.Mode/v1/is_dark".text = ''
      true
    '';

    xdg.configFile."com.system76.CosmicTk/v1/header_size".text = ''
      Spacious
    '';

    xdg.configFile."com.system76.CosmicTk/v1/icon_theme".text = ''
      "Cosmic"
    '';

    xdg.configFile."com.system76.CosmicTk/v1/interface_density".text = ''
      Spacious
    '';

    xdg.configFile."com.system76.CosmicTk/v1/interface_font".text = ''
      (
          family: "JetBrainsMono Nerd Font",
          weight: Normal,
          stretch: Normal,
          style: Normal,
      )
    '';

    xdg.configFile."com.system76.CosmicTk/v1/monospace_font".text = ''
      (
          family: "JetBrainsMonoNL Nerd Font Mono",
          weight: Normal,
          stretch: Normal,
          style: Normal,
      )
    '';
  };
}
