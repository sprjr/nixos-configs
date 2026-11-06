+++
title = "Blacklisting the eMudhra roots on NixOS"
date = 2026-11-06

[taxonomies]
topic = ["technical"]
tags = ["nix", "tls", "pki"]
+++

I'm publishing this way late, definitely after it actually matters; however, I've already implemented the solution, and I didn't decide to do articles on a personal site until just a few days ago, and this seems like a nice little piece to add and may be useful for future issues with a bit of tailoring.

## The Problem

There are tons of articles published due to the global and high-impact nature of this issue. Without diving into the nitty-gritty of the issue itself, suffice it to say that a company named eMudhra exited the TLS business after it was shown that eight of its intermediate CA certificates had private keys weak enough to derive from the public certificates.

### Timeline

The issue was flagged by a cybersecurity researcher on 10-17-2026. eMudhra revoked all eight intermediates on 10-18, Sectigo revoked its cross-signed copies the following day, and Mozilla distrusted the emSign ECC Root CA - G3 on 10-20. Five days after the report, eMudhra announced its exit. I personally feel that they're dodging a lot of the responsibility around their poor implementation of their CA keys (one of which was just the number '4'), but ultimately, leaving this space was an extremely likely outcome regardless of any steps they might have taken prior to announcing their exit.

In eMudhra's own account, the affected CAs were revoked within 14 hours of discovery, no end-entity certificates were issued from them, and its infrastructure was not compromised. Kudelski Security, which published the technical advisory, found no evidence of active exploitation; Cloudflare has since documented attempted exploitation against unpatched clients.

## Solution

I'm only listing a Nix solution, and it's incredibly easy. Add the following to your host's configuration:

```nix
security.pki.caCertificateBlacklist = [
  "Comodo AAA Services root"
  "emSign ECC Root CA - G3"
];
```

Then just rebuild and voila -- you have removed both roots from this machine's CA bundle.

These are the roots the affected chains terminated at, not the eight compromised intermediates themselves: removing a root invalidates every chain through it, including chains with nothing to do with this incident.

The option only adds entries. Whatever you put here is appended to the list nixpkgs ships, so you can drop your own entries later, but not the defaults. Since 2026-10-20 the defaults include all four of the roots involved here -- `Comodo AAA Services root`, `emSign ECC Root CA - G3`, `emSign Root CA - C1` and `emSign ECC Root CA - C3` ([commit 16ac0cd8f4](https://github.com/NixOS/nixpkgs/commit/16ac0cd8f4)). On a pin newer than that, a plain rebuild is the whole fix and both entries above are duplicates. My hosts were pinned to `4533d929` from 2026-02-03, which predates the commit, which is why the manual step was needed.

## Sources

- [eMudhra to Exit global SSL/TLS Certificate Business](https://emudhra.com/en/press-release/emudhra-to-exit-global-ssl-tls-certificate-business) -- eMudhra press release, 2026-10-22. Voluntary withdrawal; states the affected CAs were revoked within 14 hours, that no end-entity certificates were issued from them, and that no infrastructure was compromised.
- [eMudhra Intermediate CA Private Key Compromise](https://kudelskisecurity.com/research/emudhra-intermediate-ca-private-key-compromise) -- Kudelski Security advisory, 2026-10-21. Lists the eight intermediates (six TLS, two code-signing), the Sectigo cross-signs that bring the total to sixteen certificates, and the revocation dates.
- [Bug 2083449 -- eMudhra: Private key compromise of Intermediate Certificates](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449) -- Mozilla CA Program record; reported 2026-10-17.
- [NSS rev 26d38a0c3fb8](https://hg-edge.mozilla.org/projects/nss/rev/26d38a0c3fb81e7fb2acedbaf4c42dd21dce0517) and [NSS rev 8159223c48ce](https://hg-edge.mozilla.org/projects/nss/rev/8159223c48ceeb1273a1915bca95a517294ab0e0) -- the distrusted-root changes NSS shipped.
- [nixpkgs commit 16ac0cd8f4](https://github.com/NixOS/nixpkgs/commit/16ac0cd8f4) -- 2026-10-20, `nixos/security/pki: distrust various roots with compromised intermediates`.
- [GO-2026-6809 / CVE-2026-111943](https://pkg.go.dev/vuln/GO-2026-6809) -- Go's denylist for the eight intermediates; fixed in 1.27.3 and 1.26.10.
- [4 real? Tracking exploitation and patching of eMudhra's weak keys](https://blog.cloudflare.com/emudhra-patching) -- Cloudflare, on attempted exploitation.
- [Disgraced eMudhra drops out of TLS business](https://arstechnica.com/security/2026/10/disgraced-emudhra-drops-out-of-tls-business-following-certificate-debacle) -- Ars Technica, 2026-10.
