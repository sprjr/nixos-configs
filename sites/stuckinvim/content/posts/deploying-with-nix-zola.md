+++
title = "Deploying this site with Nix + Zola"
date = 2026-10-30
[taxonomies]
topic = ["technical"]
tags = ["nix", "homelab"]
+++

This site is built by Zola inside a Nix derivation and served by Caddy on a Linode VPS.

## Why Zola?

Zola is a single static binary. It needs no runtime dependencies beyond the HTML it produces.

## How I deployed it

```
  { pkgs, ... }:

let
  site = pkgs.stdenvNoCC.mkDerivation {
    pname = "stuckinvim-site";
    version = "0.1.0";
    src = ../../../sites/stuckinvim;
    nativeBuildInputs = [ pkgs.zola pkgs.cacert ];

    buildPhase = ''
      runHook preBuild
      cp -r $src/. .
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      zola build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r public/. $out/
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
```
