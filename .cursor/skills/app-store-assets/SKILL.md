---
name: app-store-assets
description: Prepares App Store (Mac App Store) release materials: product name, description, promotional text, keywords, category, and locale-specific copy. Use when preparing for App Store submission, writing store listing copy, or generating multi-language app store assets.
---

# App Store Assets

## Scope

Prepares metadata and **multi-language** copy for **Mac App Store** submission. When preparing or updating assets, produce the following items and support multiple locales (see [locales.md](locales.md)).

## Required Assets

| Asset | Description | Limits / Notes |
|-------|-------------|----------------|
| **App Name** | Store listing title | ~30 characters; can pair with subtitle |
| **Subtitle** | One line under the title | ~30 characters (Mac); concise selling point |
| **Promotional Text** | Updatable promo line anytime | ~170 characters; not locked per version |
| **Description** | Full product intro, features, use cases | ~4000 characters; use short paragraphs |
| **Keywords** | Search terms, comma-separated, no spaces | ~100 characters; avoid repeating app name |
| **Category** | Primary + optional secondary | e.g. Productivity, Photo & Video |
| **What's New** | Release notes for current version | ~4000 characters; can be localized |
| **Support URL** | Help/support page | Required |
| **Privacy Policy URL** | Privacy policy page | Required if collecting data |

## Multi-Language

- **Per language**: one full set of Name, Subtitle, Promotional Text, Description, Keywords, What's New.
- Prioritize **English (en)** and **Simplified Chinese (zh-Hans)**; add others as needed (see [locales.md](locales.md)).
- Output by **language section** or **table** for easy paste into App Store Connect.

## Output Format

- Use Markdown or structured text with sections per language, e.g. `## en`, `## zh-Hans`.
- Or a table: columns = fields (Name, Subtitle, Description, Keywords…), rows = locale code.
- Keywords: single comma-separated string per locale, e.g. `screen capture,screenshot,record,region,clipboard`.

## References

- Product features and selling points: repository root `README.md`.
- Recommended locales and codes: [locales.md](locales.md).
- **Fastlane deliver** (credentials, platform, app_identifier, support_url gotchas, non-interactive): [fastlane-deliver.md](fastlane-deliver.md).
