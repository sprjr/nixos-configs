{ ... }:
{
  # eMudhra intermediate key compromise (2026) — block both chain anchors
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];
}
