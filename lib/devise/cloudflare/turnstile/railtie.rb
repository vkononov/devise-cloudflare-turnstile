module Devise
  module Cloudflare
    module Turnstile
      class Railtie < ::Rails::Railtie
        initializer 'devise_cloudflare_turnstile.controller_concern' do
          ActiveSupport.on_load(:devise_controller) do
            include Devise::Cloudflare::Turnstile::ControllerConcern
          end
        end

        initializer 'devise_cloudflare_turnstile.view_helpers' do
          ActiveSupport.on_load(:action_view) do
            include Devise::Cloudflare::Turnstile::ViewHelpers
          end
        end
      end
    end
  end
end
