# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Align project scaffolding with cloudflare-turnstile-rails: split Test/Lint
  GitHub Actions, Appraisal matrix for Rails 6–8, RuboCop plugins, ESLint, and
  README badges/docs.
- Delegate widget rendering, Cloudflare script loading, CSP nonce handling, and
  Turbo/Turbolinks re-initialization to the `cloudflare-turnstile-rails` runtime
  instead of duplicating that logic. The auto-injected widget now uses the
  standard `cf-turnstile` markup.
- Mark `create`/`update` actions as Turnstile-protected so failed submissions
  that re-render the form still emit the meta tag and scripts. Without this,
  Turbo replaces the head with a response that omits them and the widget
  disappears after validation errors.

### Removed

- `devise_turnstile_script_tag` view helper. The Cloudflare script is now loaded
  by the `cloudflare-turnstile-rails` runtime via `devise_turnstile_scripts`.

## [0.1.0]

### Added

- Automatic Cloudflare Turnstile protection for all Devise `create` actions.
- Auto-injection of the Turnstile widget into Devise forms via JavaScript.
- Install generator that creates an initializer and updates the application layout.
