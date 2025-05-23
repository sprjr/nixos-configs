# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "apps/psensor" = {
      graph-alpha-channel-enabled = false;
      graph-background-alpha = 1.0;
      graph-background-color = "#e8f4e8f4a8f5";
      graph-foreground-color = "#000000000000";
      graph-monitoring-duration = 20;
      graph-update-interval = 2;
      interface-hide-on-startup = false;
      interface-window-divider-pos = 0;
      interface-window-h = 200;
      interface-window-restore-enabled = true;
      interface-window-w = 800;
      interface-window-x = 0;
      interface-window-y = 0;
      sensor-update-interval = 2;
      slog-enabled = false;
      slog-interval = 300;
    };

    "org/blueman/general" = {
      window-properties = [ 891 457 2996 1330 ];
    };

    "org/gnome/Extensions" = {
      window-height = 863;
      window-width = 1066;
    };

    "org/gnome/control-center" = {
      last-panel = "multitasking";
      window-state = mkTuple [ 980 640 false ];
    };

    "org/gnome/desktop/a11y/applications" = {
      screen-reader-enabled = false;
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [ "Utilities" "YaST" "Pardus" ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [ "gnome-abrt.desktop" "gnome-system-log.desktop" "nm-connection-editor.desktop" "org.gnome.baobab.desktop" "org.gnome.Connections.desktop" "org.gnome.DejaDup.desktop" "org.gnome.Dictionary.desktop" "org.gnome.DiskUtility.desktop" "org.gnome.Evince.desktop" "org.gnome.FileRoller.desktop" "org.gnome.fonts.desktop" "org.gnome.Loupe.desktop" "org.gnome.seahorse.Application.desktop" "org.gnome.tweaks.desktop" "org.gnome.Usage.desktop" "vinagre.desktop" ];
      categories = [ "X-GNOME-Utilities" ];
      name = "X-GNOME-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///home/patrick/.local/share/backgrounds/2024-10-30-16-40-08-purple_tree.jpg";
      picture-uri-dark = "file:///home/patrick/.local/share/backgrounds/2024-10-30-16-40-08-purple_tree.jpg";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/input-sources" = {
      show-all-sources = false;
      sources = [ (mkTuple [ "xkb" "us" ]) ];
      xkb-options = [ "terminate:ctrl_alt_bksp" ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-size = 24;
      document-font-name = "Hack Nerd Font Mono 11";
      enable-animations = true;
      enable-hot-corners = true;
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      font-name = "Hack Nerd Font,  10";
      gtk-theme = "Adwaita";
      icon-theme = "Adwaita";
      monospace-font-name = "Hack Nerd Font Mono 10";
      scaling-factor = mkUint32 1;
      text-scaling-factor = 1.0;
      toolbar-style = "text";
    };

    "org/gnome/desktop/notifications" = {
      application-children = [ "signal-desktop" "steam" "firefox" "gnome-power-panel" "org-gnome-tweaks" "org-gnome-nautilus" "org-gnome-extensions" ];
    };

    "org/gnome/desktop/notifications/application/com-nextcloud-desktopclient-nextcloud" = {
      application-id = "com.nextcloud.desktopclient.nextcloud.desktop";
    };

    "org/gnome/desktop/notifications/application/firefox" = {
      application-id = "firefox.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-extensions" = {
      application-id = "org.gnome.Extensions.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-nautilus" = {
      application-id = "org.gnome.Nautilus.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-tweaks" = {
      application-id = "org.gnome.tweaks.desktop";
    };

    "org/gnome/desktop/notifications/application/org-kde-kdeconnect-daemon" = {
      application-id = "org.kde.kdeconnect.daemon.desktop";
    };

    "org/gnome/desktop/notifications/application/org-kde-konsole" = {
      application-id = "org.kde.konsole.desktop";
    };

    "org/gnome/desktop/notifications/application/signal-desktop" = {
      application-id = "signal-desktop.desktop";
    };

    "org/gnome/desktop/notifications/application/steam" = {
      application-id = "steam.desktop";
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
      speed = 0.289062;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/privacy" = {
      old-files-age = mkUint32 30;
      recent-files-max-age = -1;
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///home/patrick/.local/share/backgrounds/2024-10-30-16-40-08-purple_tree.jpg";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/search-providers" = {
      sort-order = [ "org.gnome.Contacts.desktop" "org.gnome.Documents.desktop" "org.gnome.Nautilus.desktop" ];
    };

    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 300;
    };

    "org/gnome/desktop/sound" = {
      theme-name = "ocean";
    };

    "org/gnome/desktop/wm/keybindings" = {
      maximize = [];
      unmaximize = [];
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "icon:minimize,maximize,close";
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/mutter" = {
      edge-tiling = false;
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [];
      toggle-tiled-right = [];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = mkTuple [ 890 550 ];
    };

    "org/gnome/portal/filechooser/gnome-display-panel" = {
      last-folder-path = "/home/patrick/Nextcloud/Photos/Wallpapers/Desktop";
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };

    "org/gnome/shell" = {
      disabled-extensions = [ "apps-menu@gnome-shell-extensions.gcampax.github.com" "auto-move-windows@gnome-shell-extensions.gcampax.github.com" "launch-new-instance@gnome-shell-extensions.gcampax.github.com" "light-style@gnome-shell-extensions.gcampax.github.com" "native-window-placement@gnome-shell-extensions.gcampax.github.com" "drive-menu@gnome-shell-extensions.gcampax.github.com" "places-menu@gnome-shell-extensions.gcampax.github.com" "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com" "system-monitor@gnome-shell-extensions.gcampax.github.com" "window-list@gnome-shell-extensions.gcampax.github.com" "windowsNavigator@gnome-shell-extensions.gcampax.github.com" "workspace-indicator@gnome-shell-extensions.gcampax.github.com" "TopIcons@phocean.net" ];
      enabled-extensions = [ "smart-auto-move@khimaros.com" "caffeine@patapon.info" "blur-my-shell@aunetx" "drop-down-terminal@gs-extensions.zzrough.org" "user-theme@gnome-shell-extensions.gcampax.github.com" "memento-mori@paveloom" "brightness_control@lmedinas.org" "tiling-assistant@leleat-on-github" "hide-cursor@elcste.com" "Poppy_Menu@dies" "trayIconsReloaded@selfmade.pl" "just-perfection-desktop@just-perfection" "pano@elhan.io" "clipboard-indicator@tudmotu.com" ];
      favorite-apps = [ "org.gnome.Nautilus.desktop" "net.lutris.Lutris.desktop" ];
      last-selected-power-profile = "power-saver";
      welcome-dialog-last-shown-version = "46.4";
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.6;
      pipeline = "pipeline_default_rounded";
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0;
    };

    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      brightness = 0.6;
      pipeline = "pipeline_default";
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/caffeine" = {
      countdown-timer = 3600;
      indicator-position = 0;
      indicator-position-index = 0;
      indicator-position-max = 4;
      show-indicator = "always";
    };

    "org/gnome/shell/extensions/clipboard-indicator" = {
      history-size = 20;
    };

    "org/gnome/shell/extensions/just-perfection" = {
      accessibility-menu = true;
      activities-button = false;
      background-menu = true;
      calendar = true;
      clock-menu = true;
      clock-menu-position = 1;
      clock-menu-position-offset = 0;
      controls-manager-spacing-size = 0;
      dash = true;
      dash-icon-size = 22;
      double-super-to-appgrid = true;
      events-button = true;
      keyboard-layout = true;
      max-displayed-search-results = 0;
      osd = true;
      panel = true;
      panel-button-padding-size = 0;
      panel-icon-size = 16;
      panel-in-overview = true;
      panel-notification-icon = true;
      panel-size = 40;
      power-icon = false;
      quick-settings = true;
      quick-settings-dark-mode = true;
      ripple-box = true;
      search = true;
      show-apps-button = true;
      startup-status = 1;
      theme = false;
      top-panel-position = 0;
      weather = true;
      window-demands-attention-focus = false;
      window-picker-icon = true;
      window-preview-caption = true;
      window-preview-close-button = true;
      workspace = true;
      workspace-background-corner-size = 0;
      workspace-popup = true;
      workspace-wrap-around = false;
      workspaces-in-app-grid = true;
      world-clock = true;
    };

    "org/gnome/shell/extensions/memento-mori" = {
      birth-day = 7;
      birth-month = 4;
      birth-year = 1997;
    };

    "org/gnome/shell/extensions/smart-auto-move" = {
      activate-workspace = true;
      debug-logging = false;
      freeze-saves = false;
      ignore-position = false;
      ignore-workspace = false;
      match-threshold = 0.7;
      overrides = ''
        {}
      '';
      save-frequency = 1000;
      saved-windows = ''
        {"konsole":[{"id":1477739900,"hash":1477739900,"sequence":2,"title":"~ : zellij — Konsole","workspace":0,"maximized":3,"fullscreen":false,"above":false,"monitor":2,"x":4000,"y":360,"width":1920,"height":1080,"occupied":true}],"firefox":[{"id":1477739904,"hash":1477739904,"sequence":6,"title":"(1) Google Messages for web — Mozilla Firefox","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":1,"x":770,"y":0,"width":670,"height":680,"occupied":true},{"id":1477739902,"hash":1477739902,"sequence":4,"title":"WITHOUT YOU - Instrumental • INST — Mozilla Firefox","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":1,"x":0,"y":681,"width":1440,"height":898,"occupied":true},{"id":3841966264,"hash":3841966264,"sequence":2,"title":"Inbox (2) - patrick.rawlinson@patriotmed.us - patriotmed.us Mail — Mozilla Firefox","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":1,"x":0,"y":1580,"width":1440,"height":980,"occupied":false},{"id":3485263234,"hash":3485263234,"sequence":6,"title":"nix-community/dconf2nix: :feet: Convert dconf files (e.g. GNOME Shell) to Nix, as expected by Home Manager [maintainer=@jtojnar] — Mozilla Firefox","workspace":0,"maximized":3,"fullscreen":false,"above":false,"monitor":0,"x":1440,"y":40,"width":2560,"height":1400,"occupied":false},{"id":3485263248,"hash":3485263248,"sequence":20,"title":"Extension: (Bitwarden Password Manager) - Bitwarden — Mozilla Firefox","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":1,"x":49,"y":49,"width":380,"height":667,"occupied":false},{"id":1477739903,"hash":1477739903,"sequence":5,"title":"Clipboard Indicator - GNOME Shell Extensions — Mozilla Firefox","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1636,"y":93,"width":2074,"height":1229,"occupied":true},{"id":1477739901,"hash":1477739901,"sequence":3,"title":"Meet - IT — Mozilla Firefox","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":1,"x":0,"y":1580,"width":1440,"height":980,"occupied":true},{"id":3841966279,"hash":3841966279,"sequence":17,"title":"Restore from Backup · Kareadita/Kavita · Discussion #3016 — Mozilla Firefox","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1752,"y":75,"width":2074,"height":1229,"occupied":false}],"org.gnome.Extensions":[{"id":1477739945,"hash":1477739945,"sequence":47,"title":"Extensions","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1700,"y":390,"width":1066,"height":863,"occupied":false}],"Signal":[{"id":1477739905,"hash":1477739905,"sequence":7,"title":"Signal","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":1,"x":0,"y":0,"width":769,"height":680,"occupied":true}],"org.gnome.tweaks":[{"id":1860511694,"hash":1860511694,"sequence":16,"title":"GNOME Tweaks","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1539,"y":765,"width":980,"height":640,"occupied":false}],"org.gnome.Software":[{"id":3288821509,"hash":3288821509,"sequence":62,"title":"Software","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1440,"y":29,"width":1200,"height":800,"occupied":false}],"Bitwarden":[{"id":1477739899,"hash":1477739899,"sequence":1,"title":"Bitwarden","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1498,"y":50,"width":1086,"height":721,"occupied":true}],"lutris":[{"id":1477739908,"hash":1477739908,"sequence":10,"title":"Lutris","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1497,"y":784,"width":998,"height":634,"occupied":true}],"steam":[{"id":1477739943,"hash":1477739943,"sequence":45,"title":"Steam","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":2589,"y":49,"width":1284,"height":719,"occupied":true},{"id":3190286588,"hash":3190286588,"sequence":12,"title":"Special Offers","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":2857,"y":181,"width":706,"height":830,"occupied":false},{"id":1477739922,"hash":1477739922,"sequence":24,"title":"Steam Settings","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":2785,"y":235,"width":850,"height":722,"occupied":false},{"id":3485263269,"hash":3485263269,"sequence":41,"title":"Launching...","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1876,"y":331,"width":600,"height":286,"occupied":false},{"id":3485263265,"hash":3485263265,"sequence":37,"title":"Install","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1906,"y":234,"width":540,"height":480,"occupied":false}],"org.gnome.Nautilus":[{"id":3190286590,"hash":3190286590,"sequence":14,"title":"1.0 TB Volume","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1440,"y":29,"width":890,"height":550,"occupied":false},{"id":30826475,"hash":30826475,"sequence":23,"title":"Documents","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":2732,"y":755,"width":890,"height":550,"occupied":false},{"id":2644414027,"hash":2644414027,"sequence":22,"title":"1.0 TB Volume","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1440,"y":40,"width":890,"height":550,"occupied":false},{"id":3485263262,"hash":3485263262,"sequence":34,"title":"1.0 TB Volume","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1485,"y":89,"width":890,"height":550,"occupied":false},{"id":3841966281,"hash":3841966281,"sequence":19,"title":"Downloads","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1535,"y":136,"width":890,"height":550,"occupied":false},{"id":3841966321,"hash":3841966321,"sequence":59,"title":"1.0 TB Volume","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1440,"y":40,"width":890,"height":550,"occupied":false},{"id":2224866808,"hash":2224866808,"sequence":18,"title":"1.0 TB Volume","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1440,"y":40,"width":890,"height":550,"occupied":false},{"id":1477739918,"hash":1477739918,"sequence":20,"title":"1.0 TB Volume","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":2985,"y":774,"width":890,"height":550,"occupied":true}],"dolphin":[{"id":3190286602,"hash":3190286602,"sequence":26,"title":"931.5 GiB Internal Drive (sdc) — Dolphin","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":2210,"y":1427,"width":1202,"height":687,"occupied":false},{"id":30826473,"hash":30826473,"sequence":21,"title":"Trash — Dolphin","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1776,"y":378,"width":1202,"height":687,"occupied":false}],"org.gnome.Settings":[{"id":3841966365,"hash":3841966365,"sequence":103,"title":"Settings","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1499,"y":464,"width":980,"height":640,"occupied":false}],"steam_app_669330":[{"id":1477739941,"hash":1477739941,"sequence":43,"title":"Mechabellum","workspace":0,"maximized":0,"fullscreen":true,"above":false,"monitor":0,"x":1440,"y":0,"width":2560,"height":1440,"occupied":false}],".guake-wrapped":[{"id":30826528,"hash":30826528,"sequence":76,"title":"Guake Preferences","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1822,"y":325,"width":1154,"height":774,"occupied":false}],"org.remmina.Remmina":[{"id":30826560,"hash":30826560,"sequence":108,"title":"Remmina Remote Desktop Client","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1490,"y":79,"width":1148,"height":842,"occupied":false},{"id":30826561,"hash":30826561,"sequence":109,"title":"SXR AD - Patrick","workspace":0,"maximized":3,"fullscreen":false,"above":false,"monitor":0,"x":1440,"y":29,"width":2560,"height":1411,"occupied":false}],"Paradox Launcher":[{"id":3841966341,"hash":3841966341,"sequence":79,"title":"Stellaris","workspace":0,"maximized":0,"fullscreen":false,"above":false,"monitor":0,"x":1853,"y":642,"width":1280,"height":670,"occupied":false}],"stellaris":[{"id":3841966344,"hash":3841966344,"sequence":82,"title":"Stellaris","workspace":0,"maximized":0,"fullscreen":true,"above":false,"monitor":0,"x":1440,"y":0,"width":2560,"height":1440,"occupied":false}],"steam_app_553850":[{"id":3841966374,"hash":3841966374,"sequence":112,"title":"HELLDIVERS™ 2","workspace":0,"maximized":0,"fullscreen":true,"above":false,"monitor":0,"x":1440,"y":0,"width":2560,"height":1440,"occupied":false}]}
      '';
      startup-delay = 2500;
      sync-frequency = 100;
      sync-mode = "RESTORE";
    };

    "org/gnome/shell/extensions/tiling-assistant" = {
      activate-layout0 = [];
      activate-layout1 = [];
      activate-layout2 = [];
      activate-layout3 = [];
      active-window-hint = 1;
      active-window-hint-color = "rgb(53,132,228)";
      auto-tile = [];
      center-window = [];
      debugging-free-rects = [];
      debugging-show-tiled-rects = [];
      default-move-mode = 0;
      dynamic-keybinding-behavior = 0;
      focus-hint-color = "rgb(53,132,228)";
      import-layout-examples = false;
      last-version-installed = 49;
      restore-window = [ "<Super>Down" ];
      search-popup-layout = [];
      single-screen-gap = 0;
      tile-bottom-half = [ "<Super>KP_2" ];
      tile-bottom-half-ignore-ta = [];
      tile-bottomleft-quarter = [ "<Super>KP_1" ];
      tile-bottomleft-quarter-ignore-ta = [];
      tile-bottomright-quarter = [ "<Super>KP_3" ];
      tile-bottomright-quarter-ignore-ta = [];
      tile-edit-mode = [];
      tile-left-half = [ "<Super>Left" "<Super>KP_4" ];
      tile-left-half-ignore-ta = [];
      tile-maximize = [ "<Super>Up" "<Super>KP_5" ];
      tile-maximize-horizontally = [];
      tile-maximize-vertically = [];
      tile-right-half = [ "<Super>Right" "<Super>KP_6" ];
      tile-right-half-ignore-ta = [];
      tile-top-half = [ "<Super>KP_8" ];
      tile-top-half-ignore-ta = [];
      tile-topleft-quarter = [ "<Super>KP_7" ];
      tile-topleft-quarter-ignore-ta = [];
      tile-topright-quarter = [ "<Super>KP_9" ];
      tile-topright-quarter-ignore-ta = [];
      tiling-popup-all-workspace = true;
      toggle-always-on-top = [];
      toggle-tiling-popup = [];
      window-gap = 0;
    };

    "org/gnome/shell/extensions/trayIconsReloaded" = {
      applications = "[{\"id\":\"org.remmina.Remmina.desktop\",\"hidden\":false},{\"id\":\"bitwarden.desktop\",\"hidden\":false},{\"id\":\"net.lutris.Lutris.desktop\",\"hidden\":false},{\"id\":\"firefox.desktop\"},{\"id\":\"org.kde.kate.desktop\"}]";
      icon-brightness = 0;
      icon-contrast = 0;
      icon-margin-horizontal = 4;
      icon-margin-vertical = 0;
      icon-padding-horizontal = 0;
      icon-padding-vertical = 0;
      icon-saturation = 10;
      icon-size = 17;
      icons-limit = 15;
      position-weight = 5;
      tray-margin-left = 7;
      tray-margin-right = 0;
      tray-position = "left";
    };

    "org/gnome/shell/world-clocks" = {
      locations = [];
    };

    "org/gnome/software" = {
      check-timestamp = mkInt64 1730818744;
      first-run = false;
      flatpak-purge-timestamp = mkInt64 1730913633;
    };

    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      sidebar-width = 140;
      sort-column = "name";
      sort-directories-first = true;
      sort-order = "ascending";
      type-format = "category";
      view-type = "list";
      window-size = mkTuple [ 857 372 ];
    };

    "org/gtk/settings/color-chooser" = {
      custom-colors = [ (mkTuple [ 2.3529e-2 0.594247 0.603922 1.0 ]) (mkTuple [ 5.4902e-2 0.678431 0.411765 1.0 ]) (mkTuple [ 0.0 0.858824 0.376471 1.0 ]) (mkTuple [ 1.0 0.921569 6.2745e-2 1.0 ]) (mkTuple [ 1.0 0.521569 0.105882 1.0 ]) (mkTuple [ 1.0 0.254902 0.211765 1.0 ]) (mkTuple [ 0.498039 0.137255 1.0 1.0 ]) (mkTuple [ 9.8039e-2 0.45098 1.0 1.0 ]) ];
      selected-color = mkTuple [ true 2.3529e-2 0.594247 0.603922 1.0 ];
    };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 374;
      sort-column = "modified";
      sort-directories-first = false;
      sort-order = "descending";
      type-format = "category";
      window-position = mkTuple [ 26 23 ];
      window-size = mkTuple [ 1151 822 ];
    };

    "org/guake/general" = {
      compat-delete = "delete-sequence";
      display-n = 0;
      display-tab-names = 1;
      gtk-prefer-dark-theme = true;
      gtk-theme-name = "Default";
      gtk-use-system-default-theme = false;
      hide-tabs-if-one-tab = false;
      history-size = 1000;
      load-guake-yml = true;
      max-tab-name-length = 100;
      mouse-display = true;
      open-tab-cwd = true;
      prompt-on-quit = true;
      quick-open-command-line = "gedit %(file_path)s";
      restore-tabs-notify = true;
      restore-tabs-startup = true;
      save-tabs-when-changed = true;
      schema-version = "3.10";
      scroll-keystroke = true;
      search-engine = 1;
      use-default-font = true;
      use-popup = true;
      use-scrollbar = true;
      use-trayicon = true;
      window-halignment = 0;
      window-height = 75;
      window-losefocus = false;
      window-refocus = false;
      window-tabbar = true;
      window-width = 100;
    };

    "org/guake/keybindings/global" = {
      show-hide = "<Primary>grave";
    };

    "org/guake/style" = {
      cursor-shape = 1;
    };

    "org/guake/style/background" = {
      transparency = 85;
    };

    "org/guake/style/font" = {
      allow-bold = true;
      palette = "#3B3B42425252:#BFBF61616A6A:#A3A3BEBE8C8C:#EBEBCBCB8B8B:#8181A1A1C1C1:#B4B48E8EADAD:#8888C0C0D0D0:#E5E5E9E9F0F0:#4C4C56566A6A:#BFBF61616A6A:#A3A3BEBE8C8C:#EBEBCBCB8B8B:#8181A1A1C1C1:#B4B48E8EADAD:#8F8FBCBCBBBB:#ECECEFEFF4F4:#D8D8DEDEE9E9:#2E2E34344040";
      palette-name = "Nord";
    };

  };
}
