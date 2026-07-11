# Cloudflare Turnstile configuration
#
# This gem automatically protects all Devise forms with Cloudflare Turnstile.
#
# Get your keys from: https://dash.cloudflare.com/turnstile
#
# For testing/development, you can use dummy keys:
#   Site Key:   1x00000000000000000000AA (always passes)
#   Secret Key: 1x0000000000000000000000000000000AA (always passes)
#
# For more dummy keys and testing scenarios, see:
#   https://developers.cloudflare.com/turnstile/troubleshooting/testing/

Cloudflare::Turnstile::Rails.configure do |config|
  config.site_key   = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', nil)
  config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', nil)
end
