{ config, pkgs, ... }:

{
  home.file."test-home-file.txt".text = "hello world";
}
