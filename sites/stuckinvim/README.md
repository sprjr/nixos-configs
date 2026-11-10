# stuck in vim

Source for [stuckinvim.io](https://stuckinvim.io), a terminal-centric homelab journal covering
NixOS, self-hosted tooling, and the mistakes that follow.

Static site built with [Zola](https://www.getzola.org/) 0.23.6 — Markdown content with Tera
templates, no JavaScript toolchain, no CMS, and no runtime behind the vhost.

## Content model

`content/posts/` is the canonical post section. Every published article lives there and takes its
URL from its filename.

`content/technical/` and `content/personal/` are filtered views over a hidden `topic` taxonomy
(`render = false` in `zola.toml`), not separate content trees. A post carries
`topic = ["technical"]`, `["personal"]`, or both, which is what places it on those pages while it
still appears once in the mixed `/posts/` list.

`content/about.md`, `content/projects.md`, and `content/reading.md` are standalone pages.

Two pages are data-driven rather than prose: `data/projects.toml` supplies the rows rendered by
the projects page, and `data/reading.toml` groups the RSS subscriptions and channels listed on the
reading page.

The `tags` taxonomy is rendered at `/tags/`. The `topic` taxonomy is hidden and exists only to
drive the two view sections.

## Templates

`templates/base.html` carries the shell and the navigation. `index.html` is the home page,
`section.html` the post list, `topic_section.html` the technical/personal views, and `page.html`
the single-post layout. `projects.html` and `reading.html` are the data-driven pages,
`tags/list.html` and `tags/single.html` the taxonomy pages, and `404.html` the not-found page.

Syntax highlighting uses a Catppuccin Mocha scheme shipped in `themes/` and registered through
`[markdown.highlighting]`; it is not syntect's bundled palette. `static/style.css` is the only
stylesheet, and `static/robots.txt` is served verbatim.

The site publishes `atom.xml` and `sitemap.xml` at the root.

## Build

`nixos/modules/web/stuckinvim-blog.nix` packages the site as a `stdenvNoCC` derivation: it copies
the source into the build directory, runs `zola build` against the pinned Zola, and installs
`public/` as the derivation output. `pkgs.cacert` and `SSL_CERT_FILE` are part of the build
because Zola constructs an HTTP client at startup even when nothing is fetched.

## Deployment

The same module declares the Caddy vhosts: `stuckinvim.io` serves the built output over ACME TLS
with gzip/zstd encoding, and `www.stuckinvim.io` redirects permanently to the apex. The vhost runs
on `ds9`. Pushing to `main` is the deploy — the host picks the change up through comin, and there
is no separate publishing step.
