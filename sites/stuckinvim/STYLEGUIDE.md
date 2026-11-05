# StuckInVim site style guide

Codifies the decisions already in the site. When in doubt, read the actual files; do not add features that are not there.

## Stack and deploy

- Generator: Zola `0.23.6` from the pinned nixpkgs (`nixos/modules/web/stuckinvim-blog.nix` line 8).
- Build: `pkgs.stdenvNoCC.mkDerivation` copies `$src/.` into the build directory and runs `zola build`. It does **not** use `--root $src`.
- Host: served by Caddy on the `ds9` NixOS host (`flake.nix` lines 432 and 448).
- TLS: `tls acme@rawliyosh.com` in `nixos/modules/web/stuckinvim-blog.nix` line 32.
- Redirect: `www.stuckinvim.io` 301s to `https://stuckinvim.io{uri}` (`nixos/modules/web/stuckinvim-blog.nix` line 36).
- Deploy: commit to `main` is picked up by comin on `ds9`; no manual build step, no CMS, no admin UI.

## Taxonomies and sections

- `tags` is a normal rendered taxonomy (`zola.toml` lines 19–21; templates in `templates/tags/`).
- `topic` is a taxonomy with `render = false` (`zola.toml` lines 22–24). It is used only to classify posts.
- `/technical/` and `/personal/` are real sections (`content/technical/_index.md`, `content/personal/_index.md`). Their `_index.md` sets `extra.topic` and uses `template = "topic_section.html"`.
- `templates/topic_section.html` pulls posts whose `topic` taxonomy value matches `section.extra.topic`.

## URLs

Generated from `zola.toml` and the section/page layout:

| Path | Source |
|------|--------|
| `/posts/<file-stem>/` | `content/posts/<file-stem>.md` |
| `/technical/` | `content/technical/_index.md` |
| `/personal/` | `content/personal/_index.md` |
| `/tags/` | `tags` taxonomy list |
| `/tags/<tag>/` | `tags` taxonomy term |
| `/about/` | `content/about.md` |
| `/atom.xml` | `generate_feeds = true`, `feed_filenames = ["atom.xml"]` |

`slugify` is `safe` for paths, taxonomies, and anchors (`zola.toml` lines 26–29), so the file stem is the slug.

## Frontmatter

TOML fenced with `+++`. Required and common fields:

```toml
+++
title = "My post title"
date = 2026-11-03
[taxonomies]
topic = ["technical"]
tags = ["nix", "homelab"]
+++
```

| Field | Required | Notes |
|-------|----------|-------|
| `title` | yes | Page title |
| `date` | yes | `YYYY-MM-DD`; used for sorting |
| `topic` | yes | Exactly one of `["technical"]` or `["personal"]` |
| `tags` | no | Lowercase strings only |
| `description` | no | Used in `<meta name="description">` |
| `draft` | no | `true` hides the page from `zola build` |

Topic values are case-sensitive. Use lowercase tags.

## Markdown

- Always tag fenced code blocks with a language: ` ```bash `, ` ```nix `, etc.
- Supported fence attributes: `,linenos` and `,hl_lines=N` from Zola's inline highlighting.
- Use `<!-- more -->` to set the summary boundary when a post needs one.
- Tables are allowed; keep them small.
- Post bodies are Tera-templated. A literal `{{` in prose must be wrapped in `{% raw %}`.

## Templates and components

- No shortcodes are used. Zola 0.23 removed shortcodes.
- The site currently defines no Tera components in `templates/components.html`; that file does not exist yet.
- Reusable markup should be added as Tera components when needed.
- Base template is `templates/base.html`; page template is `templates/page.html`; list templates are `templates/section.html` and `templates/topic_section.html`.

## Images and assets

- Shared assets (CSS, favicons, etc.) live in `static/`.
- Per-post assets should be a page bundle: `content/posts/<slug>/index.md` plus colocated files, referenced with relative paths.
- The site currently has no images; do not add a CDN or webfont loader.

## Drafts

Set `draft = true` in frontmatter. Drafts are omitted by `zola build`; preview them with `zola serve --drafts`.

## Design tokens

From `static/style.css`:

- Palette: Catppuccin Mocha, with a custom darker base `--base: #181524`.
- Links: `var(--mauve)`; headings: `var(--lavender)`; `strong`: `var(--green)`; `em`: `var(--peach)`.
- Theme: dark only; `color-scheme: dark`. The `prefers-color-scheme: light` media query only repeats `color-scheme: dark`.
- Font stack: `"Iosevka Term", "Iosevka", ui-monospace, SFMono-Regular, Menlo, monospace`.
- Measure: `46rem` max-width for nav, main, and footer.
- No JavaScript, no webfont CDN, no analytics.

## Writing tone

- First person, practical, terminal- and homelab-focused.
- Prefer concrete commands over abstraction.
- No marketing language, no filler intros, no AI-generated prose.
- The two existing posts are scaffolding; do not treat them as a full editorial model.

## Pre-publish checklist

- [ ] `title`, `date`, and exactly one `topic` are present.
- [ ] Tags are lowercase.
- [ ] Every fenced code block has a language tag.
- [ ] `draft = true` is cleared when ready.
- [ ] `zola build` is clean.
- [ ] No credentials, keys, or private material are in the post or assets.

## Non-goals

Do not add:

- A JavaScript framework.
- A vendored Zola theme.
- A CMS or admin UI.
- AI-generated prose.
- Analytics or tracking.
- A comment system.

## Open items

- `zola.toml` sets `title = "StuckInVim"` but `author = "stuck in vim"`. This inconsistency is unresolved; do not silently pick one.
- `templates/components.html` is referenced in this guide as the intended Tera components registry, but the file does not exist in the repo yet.
