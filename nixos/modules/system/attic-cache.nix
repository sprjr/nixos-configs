# Configures this host to pull from the homelab Attic binary cache on shikisha.
#
# Before deploying: generate a signing keypair and populate the public key below.
#   nix-store --generate-binary-cache-key homelab-1 /tmp/attic.private /tmp/attic.public
# Store /tmp/attic.private in SOPS as atticd/signing-key on shikisha.
# Replace the placeholder string below with the contents of /tmp/attic.public.
{ ... }:

{
  nix.settings = {
    substituters = [ "http://shikisha:8089/homelab" ];
    trusted-public-keys = [
      # Replace with output of: cat /tmp/attic.public
      # Format: "homelab-1:Base64EncodedPublicKey=="
      "homelab-1:PLACEHOLDER_REPLACE_WITH_PUBLIC_KEY=="
    ];
  };
}
