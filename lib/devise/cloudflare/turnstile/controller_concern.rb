module Devise
  module Cloudflare
    module Turnstile
      module ControllerConcern
        extend ActiveSupport::Concern

        included do
          before_action :verify_cloudflare_turnstile!, only: :create
          before_action :set_turnstile_page_marker, if: :turnstile_form_action?
        end

        private

        def verify_cloudflare_turnstile!
          self.resource ||= resource_class.new
          return if valid_turnstile?(model: resource)

          clean_up_passwords(resource) if respond_to?(:clean_up_passwords, true)
          set_minimum_password_length if respond_to?(:set_minimum_password_length, true)
          set_turnstile_page_marker
          render turnstile_failure_action, status: :unprocessable_entity
        end

        def set_turnstile_page_marker
          @_devise_turnstile_protected = true
        end

        # Include create/update so failed submissions that re-render the form
        # still emit the Turnstile meta tag and scripts. Without this, Turbo
        # merges a head that omits them and the widget never comes back.
        def turnstile_form_action?
          action_name.in?(%w[new edit create update])
        end

        def turnstile_failure_action
          action_name.in?(%w[create]) ? :new : :edit
        end
      end
    end
  end
end
