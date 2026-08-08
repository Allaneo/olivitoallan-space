# Post Cover Images

Place cover images for your blog posts and articles in this directory.

## Guidelines

### Image Specifications
- **Recommended Size**: 1200x630px (1.91:1 ratio)
- **Format**: PNG or JPG
- **File Size**: Under 500KB for performance
- **Quality**: High resolution, web-optimized

### Naming Convention
- Use the same name as your post slug
- Example: For post `my-first-post`, use `my-first-post.png`

### Usage
Reference cover images in your post frontmatter:
```yaml
---
title: "My Post Title"
cover:
    image: "/images/covers/my-first-post.png"
    alt: "Descriptive alt text for accessibility"
    caption: "Optional caption"
---
```

## Best Practices

- **Accessibility**: Always include descriptive alt text
- **Consistency**: Use similar styling/branding across covers
- **Performance**: Optimize images for web (consider using tools like TinyPNG)
- **SEO**: Cover images are used for social media sharing (Open Graph)

## Example Structure
```
images/covers/
├── welcome-post.png
├── getting-started.png
├── advanced-tips.jpg
└── README.md          # This file
```
