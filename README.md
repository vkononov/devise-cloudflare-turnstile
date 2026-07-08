# Devise Cloudflare Turnstile

Automatically protect all Devise authentication forms with Cloudflare Turnstile. Zero configuration required - just install and set your API keys.

## Features

- Automatic protection for all Devise `create` actions (sign in, sign up, password reset, etc.)
- Works with Devise extensions like devise-invitable out of the box
- Auto-injects Turnstile widget into forms via JavaScript (no view modifications needed)
- Turbo and Turbolinks compatible
- CSP nonce support

## Installation

Add the gem to your Gemfile:

```ruby
gem "devise-cloudflare-turnstile"
```

Run the installer:

```bash
bundle install
rails generate devise_cloudflare_turnstile:install
```

Set your Cloudflare Turnstile credentials via environment variables:

```bash
export CLOUDFLARE_TURNSTILE_SITE_KEY=your_site_key
export CLOUDFLARE_TURNSTILE_SECRET_KEY=your_secret_key
```

That's it! All Devise forms are now protected.

## Getting API Keys

1. Go to [Cloudflare Turnstile Dashboard](https://dash.cloudflare.com/turnstile)
2. Create a new site
3. Copy your Site Key and Secret Key

## Testing / Development

For testing, use Cloudflare's dummy keys:

| Key Type | Value | Behavior |
|----------|-------|----------|
| Site Key | `1x00000000000000000000AA` | Always passes (visible) |
| Secret Key | `1x0000000000000000000000000000000AA` | Always passes |
| Site Key | `2x00000000000000000000AB` | Always blocks (visible) |
| Secret Key | `2x0000000000000000000000000000000AA` | Always fails |

## How It Works

### Controller Protection

The gem automatically includes a `before_action` on all Devise controllers that:
1. Validates the Turnstile response on `create` actions
2. Re-renders the form with errors if validation fails

### View Integration

On `new` and `edit` actions, the gem marks the page for Turnstile protection. The included JavaScript automatically:
1. Detects forms on protected pages
2. Injects the Turnstile widget before submit buttons
3. Handles Turbo/Turbolinks navigation

### Layout Requirements

The install generator adds these helpers to your layout's `<head>`:

```erb
<%= devise_turnstile_meta_tag %>
<%= devise_turnstile_script_tag %>
<%= devise_turnstile_scripts %>
```

- `devise_turnstile_meta_tag` - Outputs the site key for JavaScript
- `cloudflare_turnstile_script_tag` - Loads the Cloudflare Turnstile script (from cloudflare-turnstile-rails)
- `devise_turnstile_scripts` - Loads the auto-inject JavaScript (only on Devise pages)

## Skipping Protection

If you need to skip Turnstile protection for a specific controller, create a custom controller:

```ruby
# app/controllers/users/confirmations_controller.rb
class Users::ConfirmationsController < Devise::ConfirmationsController
  skip_before_action :verify_cloudflare_turnstile!
end
```

Then update your routes:

```ruby
devise_for :users, controllers: { confirmations: "users/confirmations" }
```

## Dependencies

- [devise](https://github.com/heartcombo/devise) >= 4.0
- [cloudflare-turnstile-rails](https://github.com/vkononov/cloudflare-turnstile-rails) >= 1.0
- Rails >= 6.0
- Ruby >= 2.7

## License

MIT License. See [LICENSE.txt](LICENSE.txt) for details.
