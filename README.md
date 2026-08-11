# Devise Cloudflare Turnstile

[![Gem Version](https://img.shields.io/gem/v/devise-cloudflare-turnstile.svg?label=Gem&logo=rubygems&logoColor=white)](https://rubygems.org/gems/devise-cloudflare-turnstile)
[![Ruby](https://img.shields.io/badge/Ruby-2.6%20to%204.0-CC342D?logo=ruby&logoColor=white)](https://github.com/vkononov/devise-cloudflare-turnstile/blob/main/.github/workflows/test.yml)
[![Rails](https://img.shields.io/badge/Rails-5.0%20to%208.1-D30001?logo=rubyonrails&logoColor=white)](https://github.com/vkononov/devise-cloudflare-turnstile/blob/main/Appraisals)
[![Test Matrix](https://img.shields.io/github/actions/workflow/status/vkononov/devise-cloudflare-turnstile/test.yml?branch=main&label=Test%20Matrix&logo=github)](https://github.com/vkononov/devise-cloudflare-turnstile/actions/workflows/test.yml)
[![Lint](https://img.shields.io/github/actions/workflow/status/vkononov/devise-cloudflare-turnstile/lint.yml?branch=main&label=Lint&logo=github)](https://github.com/vkononov/devise-cloudflare-turnstile/actions/workflows/lint.yml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Automatically protect all Devise authentication forms with Cloudflare Turnstile. Add two helper tags to your layout, set your API keys, and every Devise form is protected — no changes to your Devise views or controllers.

Built on [cloudflare-turnstile-rails](https://github.com/vkononov/cloudflare-turnstile-rails) for verification, widget rendering, CSP nonces, and Turbo support.

Supports **Rails 5.0 → latest** and **Ruby 2.6 → latest**, with the full Rails/Ruby matrix tested daily in CI.

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png)](https://www.buymeacoffee.com/vkononov)

## Features

* **No Devise view changes**: Auto-injects the Turnstile widget into Devise forms via JavaScript.
* **Automatic verification**: Checks Turnstile on every Devise `create` action.
* **Configurable**: Skip protection per controller or action, and set widget appearance globally.
* **Plays well with your stack**: Devise extensions (e.g. devise-invitable), Turbo/Turbolinks re-renders, and CSP nonces all work out of the box.
* **Built on [cloudflare-turnstile-rails](https://github.com/vkononov/cloudflare-turnstile-rails)**: verification, script loading, and i18n error messages.

## Table of Contents

- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Getting API Keys](#getting-api-keys)
  - [How It Works](#how-it-works)
- [Choosing Protected Actions](#choosing-protected-actions)
- [Skipping Protection](#skipping-protection)
- [Customizing the Widget](#customizing-the-widget)
- [Passing Extra Verification Parameters](#passing-extra-verification-parameters)
- [How Protection Is Applied](#how-protection-is-applied)
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

Run bundle and the installer, which creates `config/initializers/cloudflare_turnstile.rb`:

```bash
bundle install
bin/rails generate devise_cloudflare_turnstile:install
```

Add these two helpers to your layout's `<head>` (e.g. `app/views/layouts/application.html.erb`):

```erb
<%= devise_turnstile_meta_tag %>
<%= devise_turnstile_scripts %>
```

Both render nothing on non-Devise pages, so they are safe to keep in a shared layout.

Set your Cloudflare Turnstile credentials via environment variables:

```bash
export CLOUDFLARE_TURNSTILE_SITE_KEY=your_site_key
export CLOUDFLARE_TURNSTILE_SECRET_KEY=your_secret_key
```

That's it — all Devise forms are now protected.

### Getting API Keys

1. Go to [Cloudflare Turnstile Dashboard](https://dash.cloudflare.com/turnstile)
2. Create a new site
3. Copy your Site Key and Secret Key

### How It Works

* **Controller** — a `before_action` on every Devise controller verifies the Turnstile response on the protected actions (`create` by default) and re-renders the form with an error if it fails.
* **View** — on Devise form pages, the two layout helpers emit the site key and load the injector JavaScript, which adds a `cf-turnstile` widget before the submit button of each form that has an input.

Widget rendering, script loading, CSP nonces, and Turbo/Turbolinks handling are delegated to [cloudflare-turnstile-rails](https://github.com/vkononov/cloudflare-turnstile-rails).

## Choosing Protected Actions

By default Turnstile protects only the `create` actions — sign in, sign up, password-reset request, and resend confirmation/unlock — which are the unauthenticated entry points. The widget appears on those forms (and their `new` pages) and nowhere else, so authenticated pages such as account settings stay untouched.

To protect additional actions, set `config.protected_actions`:

```ruby
# config/initializers/cloudflare_turnstile.rb
Cloudflare::Turnstile::Rails.configure do |config|
  # ...site_key, secret_key, etc...

  # Also protect password-reset completion and account updates.
  config.protected_actions = %w[create update]
end
```

For each protected action the widget also renders on the page that shows its form (`new` for `create`, `edit` for `update`).

## Skipping Protection

Both the widget and server-side verification are applied per Devise action. You can disable them globally from the initializer or per controller.

### Via configuration

Skip whole controllers or specific actions without creating custom controllers:

```ruby
# config/initializers/cloudflare_turnstile.rb
Cloudflare::Turnstile::Rails.configure do |config|
  # ...site_key, secret_key, etc...

  config.skip :confirmations            # every action
  config.skip passwords: :create        # a single action
  config.skip unlocks: %i[new create]   # a set of actions
end
```

Controller keys match Devise's `controller_name` (`sessions`, `registrations`, `passwords`, `confirmations`, `unlocks`, `invitations`).

### Via controller macro

If you already subclass a Devise controller, use the `skip_turnstile` macro:

```ruby
# app/controllers/users/passwords_controller.rb
module Users
  class PasswordsController < Devise::PasswordsController
    skip_turnstile # every action
    # skip_turnstile only: :create # a subset
    # skip_turnstile except: :new  # everything but a subset
  end
end
```

Then update your routes:

```ruby
devise_for :users, controllers: { passwords: 'users/passwords' }
```

Skipping an action suppresses both the widget injection and the server-side check for that action.

## Customizing the Widget

Widget appearance (theme, language, size, and any other Cloudflare `data-*` option) is configured once in the initializer via the foundational gem's `config.default_data`. These defaults are applied to every auto-injected Devise widget:

```ruby
# config/initializers/cloudflare_turnstile.rb
Cloudflare::Turnstile::Rails.configure do |config|
  config.default_data = {
    theme: 'dark',
    language: -> { I18n.locale }
  }
end
```

To use invisible or managed widgets everywhere, configure the matching widget type on your Cloudflare site key — that choice is made in the Cloudflare dashboard, not in code.

For a single form that needs different options, render a widget yourself in a custom Devise view using `cloudflare_turnstile_tag`. The injector skips any form that already contains a `.cf-turnstile` element, so your manual widget wins:

```erb
<%# app/views/users/sessions/new.html.erb %>
<%= cloudflare_turnstile_tag data: { theme: 'light' } %>
```

## Passing Extra Verification Parameters

To forward additional siteverify parameters (e.g. `remoteip`, `idempotency_key`) to Cloudflare, override `turnstile_verify_options` in a custom Devise controller:

```ruby
module Users
  class SessionsController < Devise::SessionsController
    private

    def turnstile_verify_options
      { remoteip: request.remote_ip }
    end
  end
end
```

## How Protection Is Applied

| Situation | Behavior |
|-----------|----------|
| No custom controllers | All Devise controllers are protected automatically on the create actions |
| Authenticated actions (e.g. account edit) | Not protected by default; add them to `config.protected_actions` |
| Custom controller with `skip_turnstile` (or config `skip`) | That controller/action opts out of both widget and verification |
| No custom views | Devise's default views render; the widget still injects |
| Custom view without a widget | The widget is injected before the submit button of forms that have an input |
| Custom view with `cloudflare_turnstile_tag` | Your widget is used as-is; nothing is auto-injected |
| Invisible vs visible widget | Determined by the site key's widget type in the Cloudflare dashboard |

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
