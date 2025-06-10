{ config, pkgs, home-manager, hyprsession, ... }:
{

  config = {
    wayland.windowManager.hyprland = {
  #   enable = true;
      package = pkgs.hyprland;
      xwayland.enable = true;
      systemd.enable = true;
      plugins = [
        pkgs.hyprlandPlugins.hyprspace
      ];
    };

    home.packages = with pkgs; [
      ashell
      swaynotificationcenter
      sysmenu
      ulauncher
      waybar
      wofi
    ];

    # Wallpaper
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [
          "~/Nextcloud/Photos/Wallpapers/Desktop/celestial_vortex.jpeg"
        ];
        wallpaper = [
          ",~/Nextcloud/Photos/Wallpapers/Desktop/celestial_vortex.jpeg"
        ];
      };
    };

    home.file.".config/hypr/hyprland.conf".text = ''
      # Monitors
      source = ~/.config/hypr/monitors.conf
      monitor=,preferred,auto,1

      # Workspaces
      source = ~/.config/hypr/workspaces.conf

      # Programs
      $terminal = ghostty
      $fileManager = nautilus
      $menu = ulauncher-toggle

      # Autostart
      exec-once = waybar
      exec-once = hyprpaper
      exec-once = swayosd-server
      exec-once = udiskie
      exec-once = [workspace 1 silent] ghostty
      exec-once = [workspace 2 silent] firefox
      exec-once = hyprctl setcursor Nordzy-catppuccin-frappe-dark 24
      exec-once = nm-applet --indicator
      exec-once = blueman-applet
      exec-once = ulauncher --hide-window

      # Environment Variables
      env = XCURSOR_SIZE,24
      env = HYPRCURSOR_SIZE,24
      env = HYPRCURSOR_THEME,Nordzy-hyprcursors*

      # Look and Feel
      # https://wiki.hyprland.org/Configuring/Variables/
      general {
      	gaps_in = 5
  	gaps_out = 20
  	border_size = 2
  	col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
  	col.inactive_border = rgba(595959aa)

  	# Set to true to enable resizing windows by clicking/dragging borders/gaps
  	resize_on_border = false
  	allow_tearing = false
  	layout = dwindle
      }

      decoration {
      	rounding = 10
  	active_opacity = 1.0
  	inactive_opacity = 1.0

          shadow {
  	    enabled = true
  	    range = 4
  	    render_power = 3
  	    color = rgba(1a1a1aee)
  	}

  	blur {
  	    enabled = true
  	    size = 3
  	    passes = 1
  	    vibrancy = 0.1696
  	}
      }

      animations {
      	enabled = yes, please :)
          bezier = easeOutQuint,0.23,1,0.32,1
  	bezier = EaseInOutCubic,0.65,0.05,0.36,1
  	bezier = linear,0,0,1,1
  	bezier = almostLinear,0.5,0.5,0.75,1.0
  	bezier = quick,0.15,0,0.1,1

  	animation = global, 1, 10, default
  	animation = border, 1, 5.39, easeOutQuint
  	animation = windows, 1, 4.79, easeOutQuint
  	animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
  	animation = windowsOut, 1, 1.49, linear, popin 87%
  	animation = fadeIn, 1, 1.73, almostLinear
  	animation = fadeOut, 1, 1.46, almostLinear
  	animation = fade, 1, 3.03, quick
  	animation = layers, 1, 3.81, easeOutQuint
  	animation = layersIn, 1, 4, easeOutQuint, fade
  	animation = layersOut, 1, 1.5, linear, fade
  	animation = fadeLayersIn, 1, 1.79, almostLinear
  	animation = fadeLayersOut, 1, 1.39, almostLinear
  	animation = workspaces, 1, 1.94, almostLinear, fade
  	animation = workspacesIn, 1, 1.21, almostLinear, fade
  	animation = workspacesOut, 1, 1.94, almostLinear, fade
      }

      dwindle {
         #psuedotile = true # Master switch for psuedotiling. Enabling is bound to mainMod + P
          preserve_split = true # You probably want this
      }

      misc {
          force_default_wallpaper = 0 # Set to 0 or 1 to disable anime preset wallpapers
  	disable_hyprland_logo = true # If true, disable random hyprland logo/anime girl background
      }

      group {
          auto_group = false
  	drag_into_group = 2
  	col.border_active = rgba(33ccff33) rgba(99ff88ee) 45deg
  	col.border_inactive = rgba(595959aa)
  	col.border_locked_active = rgba(33ccff33) rgba(00ff99ee) 45deg
  	col.border_locked_inactive = rgba(595959aa)

  	groupbar {
  	    font_size = 12
  	    gradients = true
  	    height = 15
  	    rounding = 0
  	    col.active = rgba(33ccff99)
  	    col.inactive = rgba(595959aa)
  	    col.locked_active = rgba(33ccff99)
  	    col.locked_inactive = rgba(595959aa)
  	}
      }

      plugin {
          overview {
  	    showNewWorkspace = false
  	    panelHeight = 200
  	    exitOnClick = true
  	    exitOnSwitch = true
  	    workspaceActiveBorder = rgba(33ccff99)
  	    workspaceBorderSize = 2
  	}
      }

      # Input
      input {
          kb_layout = us
  	kb_variant =
  	kb_model =
  	kb_options =
  	kb_rules =

  	follow_mouse = 1
  	sensitivity = 0 # -1.0 - 1.0, 0 meansno modification
  	touchpad {
  	    natural_scroll = true
  	    clickfinger_behavior = 1
  	}
      }

      gestures {
          workspace_swipe = true
      }

      # Example per-device config
      #device {
      #    name = epic-mouse-v1
      #    sensitivity = -0.5
      #}

      # Keybindings
      $mainMod = SUPER # Sets the Windows key as the main modifier

      # Binds
      bind = $mainMod, enter, exec, $terminal
      bind = $mainMod, Q, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, F, togglefloating,
      bind = $mainMod, space, exec, $menu
     #bind = $mainMod, P, psuedo, # dwindle
      bind = $mainMod, J, togglesplit, # dwindle
      bind = $SUPER_SHIFT, l, exec, hyprlock
      bind = $mainMod, D, exec, nwg-drawer
      bind = , XF86LaunchB, exec, nwg-drawer

      # Move focus with mainMod + arrow keys
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = ALT_SHIFT, 1, movetoworkspace, 1
      bind = ALT_SHIFT, 2, movetoworkspace, 2
      bind = ALT_SHIFT, 3, movetoworkspace, 3
      bind = ALT_SHIFT, 4, movetoworkspace, 4
      bind = ALT_SHIFT, 5, movetoworkspace, 5
      bind = ALT_SHIFT, 6, movetoworkspace, 6
      bind = ALT_SHIFT, 7, movetoworkspace, 7
      bind = ALT_SHIFT, 8, movetoworkspace, 8
      bind = ALT_SHIFT, 9, movetoworkspace, 9
      bind = ALT_SHIFT, 0, movetoworkspace, 10

      # Example special workspaces (scratchpad)
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      bind = $mainMod, G, togglegroup

      # Scroll through workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse-up, workspace, e-1

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      # Laptop multimedia keys for volume and LCD brightness
      bindel = ,XF86AudioRaiseVolume, exec, swayosd-client --output-volume 5
      bindel = ,XF86AudioLowerVolume, exec, swayosd-client --output-volume -5
      bindel = ,XF86AudioMute, exec, swayosd-client --output-volume mute-toggle
      bindel = ,XF86MonBrightnessUp, exec, swayosd-client --brightness raise
      bindel = ,XF86MonBrightnessDown, exec, swayosd-client --brightness lower

      bindr = CAPS,Caps_Lock, exec, swayosd-client --caps-lock

      # Requires playerctl
      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPause, exec, playerctl play-pause
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioPrev, exec, playerctl previous

      # Screenshot a window
      bind = $SUPER_SHIFT, 4, exec, hyprshot -m region

      bind = , XF86LaunchA, exec, hyprctl dispatch overview:toggle all

      # Windows and Workspaces
      # See https://wiki.hyprland.org/Configuring/Window-Rules/

      # Windowrule v1
      windowrulev2 = tile, class:Firefox, title:(Browser)(.*)
      windowrulev2 = float,,title:Ulauncher Preferences
      windowrulev2 = noborder,class:ulauncher,
      windowrulev2 = noshadow,class:ulauncher,
      windowrulev2 = noblur,class:ulauncher,

      windowrulev2 = float, class:org.gnome.NautilusPreviewer,
      windowrulev2 = float, class:Xdg-desktop-portal-gtk,
      windowrulev2 = noborder,class:Xdg-desktop-portal-gtk,
      windowrulev2 = noshadow,class:Xdg-desktop-portal-gtk,
      windowrulev2 = noblur,class:Xdg-desktop-portal-gtk,
      windowrulev2 = center,class:Xdg-desktop-portal-gtk,
      windowrulev2 = center,class:Code,

      # Ignore maximize requests from applications
      windowrulev2 = suppressevent maximize, class:.*

      # Fix some dragging issues with XWayland
      windowrulev2 = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0

      windowrulev2 = stayfocused,class:6(ulauncher)$
      windowrulev2 = stayfocused,,title:Repository Configure

      windowrulev2 = focusonactivate, class:.*
    '';
  };
}
