{ config, pkgs, lib, ... }:

let
  site = pkgs.stdenvNoCC.mkDerivation {
    pname = "stuckinvim-site";
    version = "0.1.0";
    src = ../../../sites/stuckinvim;
    nativeBuildInputs = [ pkgs.zola ];

    buildPhase = ''
      runHook preBuild
      mkdir -p .cache/zola
      zola build --root $src --base-url https://stuckinvim.io
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r public $out
      runHook postInstall
    '';
  };
in
{
  services.caddy.virtualHosts = {
    "stuckinvim.io".extraConfig = ''
      encode gzip zstd
      root * ${site}
      file_server
      tls acme@rawliyosh.com
    '';

    "www.stuckinvim.io".extraConfig = ''
      redir https://stuckinvim.io{uri} permanent
    '';
  };
}
