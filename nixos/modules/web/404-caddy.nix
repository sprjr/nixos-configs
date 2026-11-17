{ lib, pkgs }:

let
  pages = {
    stuckinvim-404 = {
      file = ./error-pages/stuckinvim-404.html;
      fileName = "404.html";
      status = 404;
    };
    rawliyosh-503 = {
      file = ./error-pages/rawliyosh-503.html;
      fileName = "index.html";
      status = 503;
      headers.Retry-After = "20";
    };
  };

  page = name: pages.${name} or (throw "404-caddy: unknown page '${name}'");

  dir = p: pkgs.writeTextDir p.fileName (builtins.readFile p.file);

  headers = h: lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "header ${k} ${v}") h);
in
{
  inherit pages;

  vhost = { name, tls ? null }: {
    extraConfig = ''
      encode gzip zstd
      ${lib.optionalString (tls != null) "tls ${tls}"}
      ${headers (page name).headers or {}}
      error ${toString (page name).status}
      handle_errors {
        rewrite * /${(page name).fileName}
        root * ${dir (page name)}
        file_server
      }
    '';
  };

  notFound = name: ''
    handle_errors {
      @notfound expression {http.error.status_code} == 404
      handle @notfound {
        rewrite * /${(page name).fileName}
        root * ${dir (page name)}
        file_server
      }
    }
  '';
}
