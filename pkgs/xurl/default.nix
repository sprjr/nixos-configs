{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "1.3.4";
  sources = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-kwuT5J1GZkuHIPvas9FnBWQbqMDCMrL3K3Oc5jX1fkM=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-axdRmm17oBLBd7UJHflgrL9ZvxSxArBViqbZ9l62av4=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "xurl: no prebuilt binary for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "xurl";
  inherit version;

  src = fetchurl {
    url = "https://github.com/xdevplatform/xurl/releases/download/v${version}/xurl_Linux_${source.arch}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 xurl $out/bin/xurl
    runHook postInstall
  '';

  meta = {
    description = "Official CLI for making authenticated requests to the X API";
    homepage = "https://github.com/xdevplatform/xurl";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "xurl";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
