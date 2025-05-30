{ pkgs, lib, config, inputs, ... }:

{
  imports = [

  ];

  options = {
    hyprland.enable = lib.mkEnableOption "enable hyprland";
  };

  config = {
    home.packages = with pkgs; [
      ashell
      swaynotificationcenter
      sysmenu
      ulauncher
      waybar
      wofi
    ];

    home.sessionVariables.XDG_CURRENT_DESKTOP = "Hyprland";

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$terminal" = "ghostty";
        "$fileManager" = "nautilus";
        "$menu" = "ulauncher-toggle";
        "mainMod" = "SUPER";

        exec-once = [
          "waybar"
          "hyprpaper"
          "swayosd-server"
          "udiskie"
          "[workspace 1 silent] ghostty"
          "[workspace 2 silent] firefox"
          "hyprctl setcursor Nordzy-catppuccin-frappe-dark 24"
          "nm-applet --indicator"
          "blueman-applet"
          "ulauncher --hide-window"
        ];

        monitor = ",preferred,auto,1";

        input = {
          kb_layout = "us";
          touchpad = {
  	  natural_scroll = "yes";
  	  clickfinger_behavior = "1";
  	  disable_while_typing = "no";
  	};
  	sensitivity = 0.1;
        };

        general = {
          gaps_in = 5;
  	gaps_out = 20;
  	border_size = 2;
  	layout = "dwindle";
  	allow_tearing = false;
  	resize_on_border = false;
        };

        misc = {
          vfr = true;
        };

        group = {
          auto_group = false;
  	drag_into_group = 2;
  	groupbar = {
  	  font_size = 12;
  	  gradients = true;
  	  height = 15;
  	  rounding = 0;
  	};
        };

        plugin = {
          overview = {
  	  showNewWorkspace = false;
  	  panelHeight = 200;
  	  exitOnClick = true;
  	  exitOnSwitch = true;
  	  workspaceActiveBorder = "rgba(33ccff99)";
  	  workspaceBorderSize = 2;
  	};
        };

        decoration = {
          rounding = 10;
  	active_opacity = 1.0;
  	inactive_opacity = 1.0;

  	blur = {
  	  enabled = true;
  	  size = 3;
  	  passes = 1;
  	  vibrancy = 0.1696;
  	};
        };

        animations = {
          enabled = 1;
  	animation = [
            "global,1,10,default"
  	  "border,1,5.39,easeOutQuint"
  	  "windows,1,4.79,easeOutQuint"
  	  "windowsIn,1,4.1,easeOutQuint,popin 87%"
  	  "windowsOut,1,1.49,linear,popin 87%"
  	  "fadeIn,1,1.73,almostLinear"
  	  "fadeOut,1,1.46,almostLinear"
  	  "fade,1,3.03,quick"
  	  "layers,1,3.81,easeOutQuint"
  	  "layersIn,1,4,easeOutQuint,fade"
  	  "layersOut,1,1.5,linear,fade"
  	  "fadeLayersIn,1,1.79,almostLinear"
  	  "fadeLayersOut,1,1.39,almostLinear"
  	  "workspaces,1,1.94,almostLinear,fade"
  	  "workspacesIn,1,1.21,almostLinear,fade"
  	  "workspacesOut,1,1.94,almostLinear,fade"
  	];
        };

        dwindle = {
          psuedotile = "yes";
          preserve_split = "yes";
        };

        gestures.workspace_swipe = "on";
        misc.force_default_wallpaper = 1;

        windowrulev2 = [
          "tile, class:Firefox, title:(Browser)(.*)"
          "float,,title:Ulauncher Preferences"
          "noborder,class:ulauncher,"
          "noshadow,class:ulauncher,"
          "noblur,class:ulauncher,"

          "float, class:org.gnome.NautilusPreviewer,"
          "float, class:Xdg-desktop-portal-gtk,"
          "noborder,class:Xdg-desktop-portal-gtk,"
          "noshadow,class:Xdg-desktop-portal-gtk,"
          "noblur,class:Xdg-desktop-portal-gtk,"
          "center,class:Xdg-desktop-portal-gtk,"
          "center,class:Code,"

          # Ignore maximize requests from applications
          "suppressevent maximize, class:.*"

          # Fix some dragging issues with XWayland"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

          "stayfocused,class:6(ulauncher)$"
          "stayfocused,,title:Repository Configure"

          "focusonactivate, class:.*"
        ];

        bind = [
          "$mainMod, enter, exec, $terminal"
          "$mainMod, Q, killactive,"
          "$mainMod, M, exit,"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, F, togglefloating,"
          "$mainMod, space, exec, $menu"
          "$mainMod, J, togglesplit, # dwindle"
          "$SUPER_SHIFT, l, exec, hyprlock"
          "$mainMod, D, exec, nwg-drawer"
          ", XF86LaunchB, exec, nwg-drawer"

          # Move focus with mainMod + arrow keys
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          # Switch workspaces with mainMod + [0-9]
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "ALT_SHIFT, 1, movetoworkspace, 1"
          "ALT_SHIFT, 2, movetoworkspace, 2"
          "ALT_SHIFT, 3, movetoworkspace, 3"
          "ALT_SHIFT, 4, movetoworkspace, 4"
          "ALT_SHIFT, 5, movetoworkspace, 5"
          "ALT_SHIFT, 6, movetoworkspace, 6"
          "ALT_SHIFT, 7, movetoworkspace, 7"
          "ALT_SHIFT, 8, movetoworkspace, 8"
          "ALT_SHIFT, 9, movetoworkspace, 9"
          "ALT_SHIFT, 0, movetoworkspace, 10"

          # Example special workspaces (scratchpad)
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          "$mainMod, G, togglegroup"

          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse-up, workspace, e-1"

          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
          "$SUPER_SHIFT, 4, exec, hyprshot -m region"
          ", XF86LaunchA, exec, hyprctl dispatch overview:toggle all"
         ];

         bindel = [
          # Laptop multimedia keys for volume and LCD brightness
          ",XF86AudioRaiseVolume, exec, swayosd-client --output-volume 5"
          ",XF86AudioLowerVolume, exec, swayosd-client --output-volume -5"
          ",XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
          ",XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
          ",XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
         ];

          bindr = [
  	  "bindr = CAPS,Caps_Lock, exec, swayosd-client --caps-lock"
  	];

          bindl = [
            # Requires playerctl
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPrev, exec, playerctl previous"
          ];
        };
      };
  };
}
