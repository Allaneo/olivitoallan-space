# Allan Eloy Olivito — Personal Website & Engineering Blog

This repository contains the source code for [olivitoallan.space](https://olivitoallan.space/), built with **Hugo** and the **Blowfish** theme.

---

## 🚀 Quick Start (Local Development)

### 1. Prerequisites
- **Git**
- **Hugo Extended** (`v0.141.0` or newer):
  ```bash
  brew install hugo
  ```

### 2. Start Local Server
Run the local development server from the repository root:
```bash
tools/scripts/dev.sh start
```
- Open `http://localhost:1313` in your browser.
- Supports **live reloading** when you edit files.
- Includes draft articles (`draft: true`) in the local preview.

### 3. Stop Local Server
```bash
tools/scripts/dev.sh stop
```

---

## ✍️ Content Creation & Publishing Workflow

### Step 1: Create a New Post
Generate a new article folder under `sites/hugo/content/posts/`:
```bash
tools/scripts/new-post.sh "My Article Title"
```

This creates a new folder with bilingual markdown files:
- `index.es.md` (Spanish version)
- `index.en.md` (English version)

### Step 2: Edit Content & Preview
Edit the files in your code editor. While you are working on an article, keep `draft: true` in the frontmatter:
```yaml
---
title: "My Article Title"
date: 2026-08-10T12:00:00-03:00
draft: true
---
```
*Draft articles are visible on `http://localhost:1313` during local dev, but are automatically excluded from the production website.*

### Step 3: Publish Content Online
When an article is ready to go live:

1. **Set draft to false**: Change `draft: true` to `draft: false` in both `index.es.md` and `index.en.md`.
2. **Commit and push to `main`**:
   ```bash
   git add .
   git commit -m "Publish post: My Article Title"
   git push origin main
   ```

---

## 🌐 Automated Deployment (GitHub Pages)

Deployment is **100% automated** via **GitHub Actions** and **GitHub Pages**:

1. Pushing commits to the `main` branch automatically triggers `.github/workflows/deploy-pages.yml`.
2. GitHub Actions compiles the Hugo site with production settings and publishes it directly to **[olivitoallan.space](https://olivitoallan.space/)**.
3. You can monitor active deployment jobs under the **Actions** tab on your GitHub repository.

> **Note**: You do **not** need AWS, Cloudflare Workers, or manual deploy scripts (`publish.sh`) for normal publishing. Pushing to `main` does everything automatically.

---

## 🛠️ Key Commands Reference

| Command | Action |
| :--- | :--- |
| `tools/scripts/dev.sh start` | Starts local Hugo server with live reload on `http://localhost:1313` |
| `tools/scripts/dev.sh stop` | Stops the running local Hugo server |
| `tools/scripts/dev.sh build` | Runs a canonical local Hugo build to test for errors |
| `tools/scripts/new-post.sh "Title"` | Generates a new bilingual article draft folder |
| `tools/scripts/article-validate.sh` | Validates article metadata formatting |

---

## 📁 Repository Structure

```text
.github/workflows/      GitHub Actions deployment workflow (deploy-pages.yml)
docs/                   Setup instructions and configuration checklists
sites/hugo/
  archetypes/           New article default templates
  assets/css/           Custom CSS styling (custom.css)
  config/               Hugo environment and language configuration
  content/              Site pages (homepage, About page, posts/)
    posts/              All blog articles (bilingual index.es.md and index.en.md)
  layouts/              Custom layout overrides
  static/               Favicons, assets, and manifests
  themes/blowfish/      Bundled Blowfish theme
tools/scripts/          Development and validation scripts
```
