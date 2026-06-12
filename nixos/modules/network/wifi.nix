{ config, lib, ... }:

let
  networks = [
    {
      name = "home";
      ssidKey = "wifi/home_ssid";
      pskKey = "wifi/home_psk";
    }
  ];

  mkKeyfile = network: ''
        mkdir -p /etc/NetworkManager/system-connections
        SSID=$(cat "${config.sops.secrets.${network.ssidKey}.path}")
        PSK=$(cat "${config.sops.secrets.${network.pskKey}.path}")
        (umask 077; cat > /etc/NetworkManager/system-connections/${network.name}.nmconnection << EOF
    [connection]
    id=${network.name}
    type=wifi
    autoconnect=true

    [wifi]
    mode=infrastructure
    ssid=''${SSID}

    [wifi-security]
    auth-alg=open
    key-mgmt=wpa-psk
    psk=''${PSK}

    [ipv4]
    method=auto

    [ipv6]
    addr-gen-mode=stable-privacy
    method=auto
    EOF
        )
  '';

  allSecretKeys = lib.concatMap (n: [
    n.ssidKey
    n.pskKey
  ]) networks;
in
lib.mkIf (networks != [ ]) {
  sops.secrets = lib.listToAttrs (map (k: lib.nameValuePair k { mode = "0400"; }) allSecretKeys);

  system.activationScripts.nm-wifi-profiles = {
    deps = [ "setupSecrets" ];
    text = lib.concatMapStrings mkKeyfile networks + ''
      if systemctl is-active NetworkManager &>/dev/null; then
        nmcli connection reload 2>/dev/null || true
      fi
    '';
  };
}
