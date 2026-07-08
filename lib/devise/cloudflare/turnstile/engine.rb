# frozen_string_literal: true

module Devise
  module Cloudflare
    module Turnstile
      class Engine < ::Rails::Engine
        initializer "devise_cloudflare_turnstile.assets" do |app|
          app.config.assets.paths << root.join("app/assets/javascripts")
          app.config.assets.precompile += %w[devise_cloudflare_turnstile.js]
        end
      end
    end
  end
end
