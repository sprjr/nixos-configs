{ config, pkgs, ... }:

{
  services.netbird.enable = true;
  environment.systemPackages = with pkgs; [
    netbird-ui
    netbird-dashboard
    netbird
  ];

  services.netbird.server = {
    enable = true;
    domain = "nb.rawliyosh.com";
    dashboard = {
      enable = true;
     #domain = "nb-admin.rawliyosh.com";
      settings = {
        AUTH_AUTHORITY = false;
        AUTH_CLIENT_ID = "cpPqiyULmD8SgqHSC6U3JqK7aHsfeBUQpt5yECt3eVqtUS9hTwEQyF5PfLc6q883";
        AUTH_AUDIENCE = "cpPqiyULmD8SgqHSC6U3JqK7aHsfeBUQpt5yECt3eVqtUS9hTwEQyF5PfLc6q883";
        AUTH_DEVICE_AUTH_CLIENT_ID = "cpPqiyULmD8SgqHSC6U3JqK7aHsfeBUQpt5yECt3eVqtUS9hTwEQyF5PfLc6q883";
        AUTH_DEVICE_AUTH_AUDIENCE = "cpPqiyULmD8SgqHSC6U3JqK7aHsfeBUQpt5yECt3eVqtUS9hTwEQyF5PfLc6q883";
        AUTH_SILENT_REDIRECT_URI= "/silent-auth";
        USE_AUTH0 = false;
        AUTH_DEVICE_AUTH_PROVIDER = "hosted";
        AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
        NETBIRD_TOKEN_SOURCE = "idToken";
      };
    };
    management = {
      enable = true;
      port = 8011;
      logLevel = "ERROR";
     #domain = "netbird.rawliyosh.com";
     #dnsDomain = "netbird.rawliyosh";
      oidcConfigEndpoint = "https://auth0.rawliyosh.com/.example/openid-configuration";
      turnPort = 3478;
      turnDomain = "";
    };
  };
}
