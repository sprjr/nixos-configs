{ config, home-manager, ... }:

{
  home.file.".config/test.txt".text = "hellow world";
}
