# Cloudflare Turnstile configuration for Devise forms.
#
# Get your keys from: https://dash.cloudflare.com/turnstile
# Dummy keys for local testing are documented in the gem README.

Cloudflare::Turnstile::Rails.configure do |config|
  config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', nil)
  config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', nil)

  # Optional: Default data-* attributes applied to every auto-injected widget
  # (and every cloudflare_turnstile_tag). Values may be a proc, evaluated at
  # render time.
  # config.default_data = {
  #   theme: 'auto',
  #   language: -> { I18n.locale }
  # }

  # This is the configuration object from cloudflare-turnstile-rails, which
  # powers this gem. For all other available options, see its README:
  # https://github.com/vkononov/cloudflare-turnstile-rails
end

# Optional: Disable Turnstile for specific Devise controllers or actions.
# Devise::Cloudflare::Turnstile.configure do |config|
#   config.skip :confirmations            # every action
#   config.skip passwords: :create        # a single action
#   config.skip unlocks: [:new, :create]  # a set of actions
# end
