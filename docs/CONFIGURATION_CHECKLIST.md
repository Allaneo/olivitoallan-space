# Configuration and launch checklist

## Required identity

- [ ] Replace `My Website` in `config/_default/languages.en.toml`.
- [ ] Replace `Site Author`, the headline, and the biography.
- [ ] Write a public site description and optional keywords.
- [ ] Set production and staging `baseURL` values.
- [ ] Review copyright ownership.

## Required content

- [ ] Replace the homepage copy.
- [ ] Replace the About page copy.
- [ ] Review every navigation item.
- [ ] Confirm the posts section is intentionally empty or add your own posts.
- [ ] Run `tools/scripts/article-validate.sh`.

## Branding

- [ ] Replace `static/favicon.svg`.
- [ ] Update `static/site.webmanifest`.
- [ ] Adjust the brand variables in `assets/css/custom.css`.
- [ ] Add and configure a logo only if needed.
- [ ] Add and configure an author image only if needed.
- [ ] Confirm image licenses permit publication.

## Optional integrations

- [ ] Keep `gtm_id` empty or provide the intended production container.
- [ ] Keep AI discussion disabled or review its prompt and providers.
- [ ] Keep disclosure disabled or provide approved disclosure copy.
- [ ] Add only public social and structured-data profile URLs.
- [ ] Add search-engine verification codes only to the intended site.

## Privacy and repository safety

- [ ] Confirm `.env` is not tracked.
- [ ] Confirm no AWS credentials, private keys, tokens, or certificates are
      stored in the repository.
- [ ] Search for personal names, email addresses, old domains, analytics IDs,
      cloud account IDs, and original-brand copy.
- [ ] Confirm generated `public/`, `resources/`, logs, and PID files are
      ignored.

## Local acceptance

- [ ] Run `tools/scripts/dev.sh build`.
- [ ] Run `tools/scripts/dev.sh start`.
- [ ] Confirm Hugo reports `Start building sites` and `Watching for changes`.
- [ ] Review home, posts, About, search, dark mode, mobile navigation, and 404.
- [ ] Create one draft with `tools/scripts/new-post.sh "Test post"`, verify its
      front matter, then remove it if it was only a test.

## AWS deployment, if used

- [ ] Copy `.env.example` to `.env`.
- [ ] Set the real domain and a unique stack prefix.
- [ ] Configure the intended AWS profile and region.
- [ ] Provide an ACM certificate ARN from `us-east-1`.
- [ ] Deploy production infrastructure and delegate DNS to Route 53.
- [ ] Deploy staging infrastructure.
- [ ] Deploy and review staging.
- [ ] Deploy production only after staging acceptance.

## Final launch

- [ ] No `example.org`, `My Website`, or `Site Author` defaults remain.
- [ ] No placeholder or copied article is published.
- [ ] Canonical URLs use the production domain.
- [ ] Production is indexable and staging is not.
- [ ] Contact, social, analytics, and legal links are intentional.
- [ ] A recovery procedure and owner are identified.

