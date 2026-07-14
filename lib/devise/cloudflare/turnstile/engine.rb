module Devise
  module Cloudflare
    module Turnstile
      class Engine < ::Rails::Engine
        initializer 'devise_cloudflare_turnstile.assets' do |app|
          next unless app.config.respond_to?(:assets)

          app.config.assets.paths << Devise::Cloudflare::Turnstile::Engine.root.join('app/assets/javascripts')
          app.config.assets.precompile += %w[devise_cloudflare_turnstile.js]
        end
      end
    end
  end
end
