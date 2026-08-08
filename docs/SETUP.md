# First-time setup

This guide takes the template from a clean clone to a configured local site.
AWS deployment is optional and comes last.

## 1. Install prerequisites

Required for local development:

- Git
- Hugo Extended 0.141 or newer

Install Hugo on macOS with:

```bash
brew install hugo
```

The Blowfish theme is bundled with the repository. No submodule initialization
or JavaScript package installation is required for a normal Hugo build.

## 2. Configure identity

Edit `sites/hugo/config/_default/languages.en.toml`.

Replace these neutral defaults:

- `title` — the browser and site title
- `copyright` — the person or organization that owns the site
- `params.description` — the default search and social description
- `params.keywords` — optional search terms
- `params.author.name`, `headline`, and `bio` — article byline details
- `params.author.links` — optional public profile links

Do not add private email addresses or account-only URLs unless you intend to
publish them.

## 3. Configure the public URL

Edit both files:

- `sites/hugo/config/_default/hugo.toml`
- `sites/hugo/config/production/hugo.toml`

Set `baseURL` to the production URL, including the trailing slash:

```toml
baseURL = "https://www.example.org/"
```

Then set the preview URL in
`sites/hugo/config/staging/hugo.toml`:

```toml
baseURL = "https://staging.example.org/"
```

The checked-in `example.org` values are safe for local builds. Deployment
scripts reject them so the template cannot be deployed accidentally.

## 4. Configure navigation and content

Edit:

- `sites/hugo/config/_default/menus.en.toml`
- `sites/hugo/content/_index.md`
- `sites/hugo/content/page/about/index.md`

The Contact menu example is commented out. Enable it only after supplying a
real public destination.

The posts section intentionally contains no articles. Create the first draft:

```bash
tools/scripts/new-post.sh "My first post"
```

Review the generated file and set `draft: false` only when it is ready to
publish.

## 5. Configure appearance

Edit `sites/hugo/config/_default/params.toml` for the color scheme, default
appearance, homepage, article metadata, and optional features.

Reusable custom styling lives in:

```text
sites/hugo/assets/css/custom.css
```

The file contains the preserved editorial layout and action-panel foundation.
Change the CSS variables near the top for a new brand before changing
structural rules.

Branding assets:

- Replace `sites/hugo/static/favicon.svg`.
- Update names, colors, and icon paths in
  `sites/hugo/static/site.webmanifest`.
- Add an author image under `sites/hugo/assets/images/author/` and uncomment
  `params.author.image` in `languages.en.toml` if desired.
- Add a logo only if the layout needs one; then set `logo` in `params.toml`.

## 6. Configure optional features

All integrations are safe by default because IDs are empty or features are
disabled.

- Set `gtm_id` in `params.toml` to enable Google Tag Manager in production.
- Set `aiDiscuss.enabled = true` to display the article discussion and sharing
  panel.
- Set `disclosure.enabled = true` and provide text to show a site-wide notice.
- Add verification values under `verification` when required.

## 7. Build and preview

Run the canonical build from the repository root:

```bash
tools/scripts/dev.sh build
```

Start the local server:

```bash
tools/scripts/dev.sh start
```

Successful startup includes `Start building sites` and `Watching for changes`.
Stop it with:

```bash
tools/scripts/dev.sh stop
```

## 8. Configure Cloudflare Pages deployment (recommended)

Create a new Cloudflare Pages project and connect your repository.

Use these build settings:

- Framework preset: `Hugo`
- Build command: `tools/scripts/dev.sh build`
- Build output directory: `sites/hugo/public`
- Environment variable: `HUGO_VERSION=0.141.0` (or newer Extended release)

After the first successful deploy:

1. Add your custom domain `olivitoallan.space` in Pages > Custom domains.
2. Keep Cloudflare preview deployments enabled for branch previews.
3. If you want `www`, add `www.olivitoallan.space` and set a redirect rule to the canonical host.

The production `baseURL` is already configured as:

```toml
baseURL = "https://olivitoallan.space/"
```

Staging/preview baseURL is configured as:

```toml
baseURL = "https://preview.olivitoallan.space/"
```

## 9. Configure AWS deployment (optional)

Prerequisites:

- AWS CLI authenticated to the intended account
- Route 53 authority for the domain
- An ACM certificate in `us-east-1` that covers the production and staging
  hostnames
- `jq` is not required by the current deployment scripts

Create local configuration:

```bash
cp .env.example .env
```

Set:

- `DOMAIN_NAME`
- `STACK_NAME_PREFIX`
- `AWS_REGION`
- `AWS_PROFILE` when needed
- `ACM_CERTIFICATE_ARN`
- optional `GOOGLE_VERIFICATION_CODE`

`.env` is ignored by Git. Never commit it or any AWS credential file.

Provision production first because it creates the hosted zone:

```bash
aws/deploy-production-infra.sh
```

Update the domain registrar to use the Route 53 name servers shown by AWS.
After DNS authority is active, provision staging:

```bash
aws/deploy-staging-infra.sh
```

Deploy site content:

```bash
tools/scripts/deploy-staging.sh
tools/scripts/deploy-production.sh
```

The content deployment scripts require a clean branch synchronized with its
remote. They do not create commits, tags, or pushes.

## 10. Final safety review

Before publishing:

```bash
tools/scripts/article-validate.sh
tools/scripts/dev.sh build
```

Then complete `docs/CONFIGURATION_CHECKLIST.md` and search the repository for
the neutral defaults `example.org`, `My Website`, and `Site Author`.
