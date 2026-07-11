# Devise Cloudflare Turnstile

[![Gem Version](https://img.shields.io/gem/v/devise-cloudflare-turnstile.svg?label=Gem&logo=rubygems&logoColor=white)](https://rubygems.org/gems/devise-cloudflare-turnstile)
[![Ruby](https://img.shields.io/badge/Ruby-2.6%20to%204.0-CC342D?logo=ruby&logoColor=white)](https://github.com/vkononov/devise-cloudflare-turnstile/blob/main/.github/workflows/test.yml)
[![Rails](https://img.shields.io/badge/Rails-5.0%20to%208.1-D30001?logo=rubyonrails&logoColor=white)](https://github.com/vkononov/devise-cloudflare-turnstile/blob/main/Appraisals)
[![Test Matrix](https://img.shields.io/github/actions/workflow/status/vkononov/devise-cloudflare-turnstile/test.yml?branch=main&label=Test%20Matrix&logo=github)](https://github.com/vkononov/devise-cloudflare-turnstile/actions/workflows/test.yml)
[![Lint](https://img.shields.io/github/actions/workflow/status/vkononov/devise-cloudflare-turnstile/lint.yml?branch=main&label=Lint&logo=github)](https://github.com/vkononov/devise-cloudflare-turnstile/actions/workflows/lint.yml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Automatically protect all Devise authentication forms with Cloudflare Turnstile. Zero configuration required — just install and set your API keys.

Built on [cloudflare-turnstile-rails](https://github.com/vkononov/cloudflare-turnstile-rails) for verification, widget rendering, CSP nonces, and Turbo support.

Supports **Rails 5.0 → latest** and **Ruby 2.6 → latest**, with the full Rails/Ruby matrix tested daily in CI.

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png)](https://www.buymeacoffee.com/vkononov)

## Features

* **Zero view changes**: Auto-injects the Turnstile widget into Devise forms via JavaScript.
* **Automatic controller protection**: Verifies Turnstile on every Devise `create` action.
* **Works with Devise extensions**: Compatible with gems like devise-invitable out of the box.
* **Delegates to cloudflare-turnstile-rails**: Verification, script loading, CSP nonces, Turbo remounting, and i18n error messages.
* **Turbo & Turbolinks compatible**: Widget reappears after validation-error re-renders.
* **CSP nonce support**: Honours Rails' `content_security_policy_nonce`.

## Table of Contents

- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Getting API Keys](#getting-api-keys)
  - [How It Works](#how-it-works)
  - [Layout Requirements](#layout-requirements)
- [Skipping Protection](#skipping-protection)
- [Automated Testing of Your Integration](#automated-testing-of-your-integration)
- [Development](#development)
  - [Setup](#setup)
  - [Running the Test Suite](#running-the-test-suite)
  - [Code Linting](#code-linting)
- [Contributing](#contributing)
- [License](#license)

## Getting Started

### Installation

Add the gem to your Gemfile:

```ruby
gem 'devise-cloudflare-turnstile'
```

Run the installer:

```bash
bundle install
bin/rails generate devise_cloudflare_turnstile:install
```

Set your Cloudflare Turnstile credentials via environment variables:

```bash
export CLOUDFLARE_TURNSTILE_SITE_KEY=your_site_key
export CLOUDFLARE_TURNSTILE_SECRET_KEY=your_secret_key
```

That's it! All Devise forms are now protected.

### Getting API Keys

1. Go to [Cloudflare Turnstile Dashboard](https://dash.cloudflare.com/turnstile)
2. Create a new site
3. Copy your Site Key and Secret Key

### How It Works

#### Controller Protection

The gem automatically includes a `before_action` on all Devise controllers that:

1. Validates the Turnstile response on `create` actions using `cloudflare-turnstile-rails`
2. Re-renders the form with errors if validation fails

#### View Integration

On Devise form actions (`new`, `edit`, and failed `create`/`update` re-renders), the gem marks the page for Turnstile protection. The included JavaScript:

1. Detects forms on protected pages
2. Injects a standard `cf-turnstile` widget before submit buttons

Rendering the widget, loading the Cloudflare script, CSP nonce handling, and Turbo/Turbolinks re-initialization are delegated to the `cloudflare-turnstile-rails` runtime.

### Layout Requirements

The install generator adds these helpers to your layout's `<head>`:

```erb
<%= devise_turnstile_meta_tag %>
<%= devise_turnstile_scripts %>
```

* `devise_turnstile_meta_tag` — Outputs the site key for the injector (only on Devise pages)
* `devise_turnstile_scripts` — Loads the `cloudflare-turnstile-rails` runtime and the auto-inject JavaScript (only on Devise pages)

## Skipping Protection

If you need to skip Turnstile protection for a specific controller, create a custom controller:

```ruby
# app/controllers/users/confirmations_controller.rb
module Users
  class ConfirmationsController < Devise::ConfirmationsController
    skip_before_action :verify_cloudflare_turnstile!
  end
end
```

Then update your routes:

```ruby
devise_for :users, controllers: { confirmations: 'users/confirmations' }
```

## Automated Testing of Your Integration

Cloudflare provides dummy sitekeys and secret keys for development and testing. See the [cloudflare-turnstile-rails testing docs](https://github.com/vkononov/cloudflare-turnstile-rails#automated-testing-of-your-integration) for the full matrix.

| Key Type | Value | Behavior |
|----------|-------|----------|
| Site Key | `1x00000000000000000000AA` | Always passes (visible) |
| Secret Key | `1x0000000000000000000000000000000AA` | Always passes |
| Site Key | `2x00000000000000000000AB` | Always blocks (visible) |
| Secret Key | `2x0000000000000000000000000000000AA` | Always fails |

## Development

### Setup

Install Ruby and JavaScript dependencies in one step:

```bash
bin/setup
npm install
```

### Running the Test Suite

[Appraisal](https://github.com/thoughtbot/appraisal) is used to run the test suite against multiple Rails versions:

```bash
bundle exec appraisal install
bundle exec appraisal rake test
```

> **CI Note:** The GitHub Action [.github/workflows/test.yml](.github/workflows/test.yml) runs this command across the supported Ruby matrix daily.

### Code Linting

Run RuboCop and ESLint together:

```bash
bin/lint
```

> **CI Note:** We run this via [.github/workflows/lint.yml](.github/workflows/lint.yml) on the latest Ruby only.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vkononov/devise-cloudflare-turnstile.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
