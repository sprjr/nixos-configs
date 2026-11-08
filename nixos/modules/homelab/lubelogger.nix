{ config, pkgs, ... }:

let
  dataDir = "/var/lib/lubelogger";
in
{
  systemd.tmpfiles.rules = [
    "d ${dataDir}/config 0755 root root -"
    "d ${dataDir}/data 0755 root root -"
    "d ${dataDir}/translations 0755 root root -"
    "d ${dataDir}/documents 0755 root root -"
    "d ${dataDir}/images 0755 root root -"
    "d ${dataDir}/temp 0755 root root -"
    "d ${dataDir}/log 0755 root root -"
    "d ${dataDir}/keys 0755 root root -"
  ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers.lubelogger = {
      image = "ghcr.io/hargata/lubelogger:latest";
      ports = [ "18080:8080" ];
      volumes = [
        "${dataDir}/config:/App/config"
        "${dataDir}/data:/App/data"
        "${dataDir}/translations:/App/wwwroot/translations"
        "${dataDir}/documents:/App/wwwroot/documents"
        "${dataDir}/images:/App/wwwroot/images"
        "${dataDir}/temp:/App/wwwroot/temp"
        "${dataDir}/log:/App/log"
        "${dataDir}/keys:/root/.aspnet/DataProtection-Keys"
      ];
      environment = {
        LC_ALL = "en_US.UTF-8";
        LANG = "en_US.UTF-8";
        LOGGING__LOGLEVEL__DEFAULT = "Error";
        MailConfig__EmailServer = "";
        MailConfig__EmailFrom = "";
        MailConfig__UseSSL = "false";
        MailConfig__Port = "587";
        MailConfig__Username = "";
        MailConfig__Password = "";
      };
    };
  };
}
