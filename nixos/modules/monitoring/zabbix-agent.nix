{ config, pkgs, ... }:

{
  services.zabbixAgent = {
    enable = true;
    listen.ip = "100.67.20.13";
    listen.port = "10050";
    openFirewall = true;
    server = "100.67.20.13";
    settings = {
      hostname = "${config.networking.hostName}";

