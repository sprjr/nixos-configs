{ config, pkgs, home-manager, ... }:

{
  services.kanshi = {
    enable = true;
    profiles = {
      local = {
        outputs = [
          {
            criteria = "DP-1";
            status = "enable";
            mode = "2560x1440@164.91";
            position = "3191,1080";
          }
          {
            criteria = "DP-2";
            status = "enable";
            mode = "2259x1271@59.96";
            position = "1920,1080";
            transform = "270";
          }
          {
            criteria = "DP-3";
            status = "enable";
            mode = "2400x1350@59.93";
            position = "5751,1080";
          }
          {
            criteria = "HDMI-A-1";
            status = "disable";
          }
        ];
      };
      remote = {
        outputs = [
          {
            criteria = "HDMI-A-1";
            status = "enable";
            mode = "1920x1080@59.96";
            position = "0,0";
          }
          { criteria = "DP-1"; status = "disable"; }
          { criteria = "DP-2"; status = "disable"; }
          { criteria = "DP-3"; status = "disable"; }
        ];
      };
    };
  };
}
