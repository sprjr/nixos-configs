{ config, pkgs, ...}:

{
  services.kanata.keyboards = {
    package = pkgs.kanata;
    enable = true;
    magic-keyboard = {
      config = ''
        (defsrc)
	(deflayermap (base-layer)
	  eject super+pgUp)
      '';
    };
  };
}
