{ config, pkgs, ... }:

{
  config.home.file.".config/test.txt".text = "hellow world";
}
