# frozen_string_literal: true

module Devise
  module Cloudflare
    module Turnstile
      module ViewHelpers
        def devise_turnstile_scripts
          return unless @_devise_turnstile_protected

          nonce = content_security_policy_nonce if respond_to?(:content_security_policy_nonce)

          javascript_include_tag(
            "devise_cloudflare_turnstile",
            defer: true,
            nonce: nonce
          )
        end

        def devise_turnstile_meta_tag
          site_key = ::Cloudflare::Turnstile::Rails.configuration.site_key
          return if site_key.nil? || site_key.empty?

          tag.meta(name: "cf-turnstile-site-key", content: site_key)
        end

        def devise_turnstile_script_tag
          script_url = ::Cloudflare::Turnstile::Rails.configuration.script_url
          return if script_url.nil? || script_url.empty?

          javascript_include_tag(
            script_url,
            async: true,
            defer: true
          )
        end
      end
    end
  end
end
