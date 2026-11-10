{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
  adwaita-icon-theme,
  hicolor-icon-theme,
}:

stdenvNoCC.mkDerivation {
  pname = "conflux-icon-theme";
  version = "0-unstable-2026-10-21";

  src = fetchFromGitHub {
    owner = "MoshiurRahmanAdib";
    repo = "Conflux-Icon-Theme";
    rev = "c175e0e550c8970fe9cb8484afe44188a8ea589f";
    hash = lib.fakeHash;
  };

  nativeBuildInputs = [ gtk3 ];

  # index.theme inherits Adwaita/hicolor; Conflux has no actions context and few symbolics.
  propagatedBuildInputs = [
    adwaita-icon-theme
    hicolor-icon-theme
  ];

  dontBuild = true;
  dontDropIconThemeCache = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons/Conflux
    cp -r index.theme apps* devices* emblems* mimes* places* preferences* status* \
      $out/share/icons/Conflux/
    gtk-update-icon-cache --force $out/share/icons/Conflux
    runHook postInstall
  '';

  meta = {
    description = "Modern, neutral Linux icon theme";
    homepage = "https://github.com/MoshiurRahmanAdib/Conflux-Icon-Theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
  };
}
