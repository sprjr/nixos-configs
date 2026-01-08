{ config, pkgs, lib, ... }:

{
  services = {
    nextcloud = {
      enable = true;
      datadir = "/mnt/unraid/Nextcloud/nextcloud";
      hostName = "nextcloud.rawliyosh.com";
      package = pkgs.nextcloud31;
      database.createLocally = true;
      configureRedis = true;
      maxUploadSize = "16G";
      https = true;
      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      # List of apps we want to install and are already packaged in
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit calendar contacts notes onlyoffice tasks cookbook qownnotesapi phonetrack spreed;
      };
      config = {
        dbtype = "pgsql";
        adminuser = "administrator";
        adminpassFile = "/tmp/nextcloud_secrets";
      };
      settings = {
        overwriteprotocol = "https";
        default_phone_region = "US";
        trusted_domains = [
          "nextcloud.rawliyosh.com"
        ];
      };
      phpOptions."opcache.interned_strings_buffer" = "16";
    };

    # Nightly database backups.
    postgresqlBackup = {
      enable = true;
      startAt = "*-*-* 01:15:00";
      location = "/var/backup/postgresql_nextcloud";
    };
  };

  # Disable the Nextcloud Setup service, it only needs to be run to set it up
  systemd.services.nextcloud-setup.enable = false;
}
