# Cloudflare Turnstile configuration for Devise forms.
#
# Get your keys from: https://dash.cloudflare.com/turnstile
# Dummy keys for local testing are documented in the gem README.

Cloudflare::Turnstile::Rails.configure do |config|
  config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', nil)
  config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', nil)
end
