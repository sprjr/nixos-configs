{ config, pkgs, inputs, ... }:

{
  environment = {
    systemPackages = [
      inputs.iwmenu.packages.${pkgs.system}.default
      inputs.bzmenu.packages.${pkgs.system}.default
      inputs.pwmenu.packages.${pkgs.system}.default
    ];
  };
}
