{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  glibc,
}:

let
  version = "1.1.3";
in
stdenv.mkDerivation {
  pname = "spacescan";
  inherit version;

  src = fetchurl {
    url = "https://github.com/a-kurczyn/spacescan/releases/download/v${version}/spacescan_${version}-1_amd64.deb";
    hash = "sha256-tgva2LdCUlb5/HVqbZ8BTfZc0nJnd7/7LGksf0zHUlA=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  buildInputs = [ glibc ];

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/spacescan $out/bin/spacescan
    mkdir -p $out/share
    cp -r usr/share/applications usr/share/icons $out/share/
    runHook postInstall
  '';

  meta = {
    description = "Disk-usage explorer for Linux: sunburst chart, keyboard-driven table, and text/CSV/JSON reports";
    homepage = "https://github.com/a-kurczyn/spacescan";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "spacescan";
    platforms = [ "x86_64-linux" ];
  };
}
