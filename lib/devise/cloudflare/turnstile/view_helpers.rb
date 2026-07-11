module Devise
  module Cloudflare
    module Turnstile
      module ViewHelpers
        def devise_turnstile_meta_tag
          return unless devise_turnstile_protected?

          site_key = ::Cloudflare::Turnstile::Rails.configuration.site_key
          return if site_key.nil? || site_key.empty?

          # Use the positional tag(name, options) form for Rails 5.0 compatibility
          # (tag.meta builder API arrived in Rails 5.1). Pass options as a Hash
          # so Ruby 3 keyword separation does not break Rails 5.0's arity.
          tag(:meta, { name: 'cf-turnstile-site-key', content: site_key })
        end

        def devise_turnstile_scripts
          return unless devise_turnstile_protected?

          nonce = content_security_policy_nonce if respond_to?(:content_security_policy_nonce)

          safe_join(
            [
              cloudflare_turnstile_loader(nonce),
              cloudflare_turnstile_injector(nonce)
            ],
            "\n"
          )
        end

        private

        def devise_turnstile_protected?
          @_devise_turnstile_protected
        end

        # Loads the cloudflare-turnstile-rails runtime, which fetches the
        # Cloudflare script and renders/re-renders every ".cf-turnstile" widget
        # (including CSP nonce and Turbo handling).
        def cloudflare_turnstile_loader(nonce)
          # Pass options as a Hash so Ruby 3 keyword separation works with
          # Rails 5.0's javascript_include_tag(*sources) signature.
          javascript_include_tag(
            'cloudflare_turnstile_helper',
            {
              async: true,
              defer: true,
              nonce: nonce,
              data: { 'script-url': ::Cloudflare::Turnstile::Rails.configuration.script_url }
            }
          )
        end

        # Injects a ".cf-turnstile" widget into every Devise form so no view
        # changes are required; rendering is delegated to the runtime above.
        def cloudflare_turnstile_injector(nonce)
          javascript_include_tag(
            'devise_cloudflare_turnstile',
            {
              defer: true,
              nonce: nonce
            }
          )
        end
      end
    end
  end
end
