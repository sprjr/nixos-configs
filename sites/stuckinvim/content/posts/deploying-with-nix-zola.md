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

## A sample table

| Tool   | Role                     |
|--------|--------------------------|
| Zola   | Static site generator    |
| Nix    | Reproducible build       |
| Caddy  | HTTPS + file server      |

## A sample code block

```nix
{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation {
  name = "stuckinvim-site";
  src = ./.;
  nativeBuildInputs = [ pkgs.zola ];
  buildPhase = ''
    zola build --root $src --base-url https://stuckinvim.io
  '';
  installPhase = ''
    cp -r public $out
  '';
}
```

## A blockquote

> The best build is the one that finishes the same way every time.

That is the point of pinning the source and the builder in one Nix flake.
