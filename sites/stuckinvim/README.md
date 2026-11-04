# stuck in vim — Zola static blog

Built with [Zola](https://www.getzola.org/) and deployed via NixOS on `ds9` behind Caddy.

## Add a post

Create a new file in `content/posts/` with front matter:

```toml
+++
title = "My post title"
date = 2026-11-03
[taxonomies]
tags = ["nix", "homelab"]
+++
```

Then write Markdown below the closing `+++`.

## Front-matter fields

| Field   | Required | Notes                                      |
|---------|----------|--------------------------------------------|
| `title` | yes      | Post title                                 |
| `date`  | yes      | `YYYY-MM-DD` used for sorting              |
| `tags`  | no       | Array of taxonomy tags                       |

## Preview locally

```bash
nix shell nixpkgs#zola --command zola serve
```

Zola will serve the site at `http://127.0.0.1:1111`.
