{ config, pkgs, ... }:

{
  home.file.".config/test.txt".text = "hellow world";
}
