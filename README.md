# Hugo Website Template

A reusable Hugo and Blowfish foundation for editorial websites. It includes
custom layouts and styling, optional AI discussion links, SEO metadata, local
development tooling, and optional AWS deployment automation.

The template ships with no articles, personal profile data, analytics IDs,
cloud account identifiers, or original-site branding.

## Start here

1. Install [Hugo Extended](https://gohugo.io/installation/).
2. Configure the site:
   - `sites/hugo/config/_default/languages.en.toml` for title and author
   - `sites/hugo/config/_default/hugo.toml` for the public URL
   - `sites/hugo/config/_default/params.toml` for appearance and features
   - `sites/hugo/config/_default/menus.en.toml` for navigation
3. Replace the generic homepage and About copy in `sites/hugo/content/`.
4. Build the site:

   ```bash
   tools/scripts/dev.sh build
   ```

5. Start local development:

   ```bash
   tools/scripts/dev.sh start
   ```

The local site is available at `http://localhost:1313`.

See [First-time setup](docs/SETUP.md) for the complete configuration path and
[the launch checklist](docs/CONFIGURATION_CHECKLIST.md) before publishing.

## Create content

```bash
tools/scripts/new-post.sh "My first post"
```

The command creates a draft under `sites/hugo/content/posts/`. No sample
article is included, so every published article belongs to the new site.

## Preserved foundation

- Blowfish theme source is bundled under `sites/hugo/themes/blowfish/`.
- Reusable custom layouts live under `sites/hugo/layouts/`.
- Reusable editorial and action-panel styles live in
  `sites/hugo/assets/css/custom.css`.
- Optional analytics, disclosure, audio, structured data, and AI discussion
  features are disabled or unconfigured by default.
- Development, validation, staging, production, and recovery scripts remain
  under `tools/scripts/`.

## Optional AWS deployment

AWS deployment is opt-in. Copy `.env.example` to `.env`, provide your domain,
stack prefix, and ACM certificate ARN, then follow the deployment section in
[the setup guide](docs/SETUP.md).

Local configuration is ignored by Git. The repository contains placeholders
only; do not add `.env`, credentials, private keys, or generated site output.

## Key commands

- `tools/scripts/dev.sh start` — start the local server
- `tools/scripts/dev.sh stop` — stop the local server
- `tools/scripts/dev.sh restart` — restart the local server
- `tools/scripts/dev.sh build` — run the canonical local build
- `tools/scripts/new-post.sh "Title"` — create a draft article
- `tools/scripts/article-validate.sh` — validate published article metadata
- `tools/scripts/deploy-staging.sh` — build and deploy staging
- `tools/scripts/deploy-production.sh` — build and deploy production

## Repository layout

```text
aws/                    Optional CloudFormation infrastructure
docs/                   Setup, checklist, and operational runbooks
sites/hugo/
  archetypes/           New-content defaults
  assets/css/           Reusable custom styling
  config/               Site, theme, and environment configuration
  content/              Generic homepage, About page, and empty posts section
  layouts/              Reusable Hugo overrides and features
  static/               Generic favicon and optional feature icons
  themes/blowfish/      Bundled upstream theme
tools/scripts/          Development, validation, and deployment automation
```
