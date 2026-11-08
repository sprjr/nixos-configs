{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-cosmic, ... }:
  let
    system = "x86_64-linux";
    cosmicPkgs = (import nixpkgs { inherit system; }).extend nixos-cosmic.overlays.default;
    mkApplet = { pname, extraBuildInputs ? [] }: cosmicPkgs.rustPlatform.buildRustPackage {
      inherit pname;
      version = "0.1.0";
      src = ./.;
      cargoLock.lockFile = ./Cargo.lock;
      cargoBuildFlags = [ "-p" pname ];
      nativeBuildInputs = with cosmicPkgs; [ pkg-config ];
      buildInputs = with cosmicPkgs; [ wayland libxkbcommon mesa ] ++ extraBuildInputs;
    };
  in
  {
    packages.${system} = {
      applet-sysinfo        = mkApplet { pname = "applet-sysinfo"; };
      applet-launcher       = mkApplet { pname = "applet-launcher"; };
      applet-homeassistant  = mkApplet { pname = "applet-homeassistant"; extraBuildInputs = [ cosmicPkgs.openssl ]; };
    };
  };
}
