# frozen_string_literal: true

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

          clean_up_passwords(resource) if resource.respond_to?(:clean_up_passwords)
          set_minimum_password_length if respond_to?(:set_minimum_password_length, true)
          set_turnstile_page_marker
          render turnstile_failure_action, status: :unprocessable_entity
        end

        def set_turnstile_page_marker
          @_devise_turnstile_protected = true
        end

        def turnstile_form_action?
          action_name.in?(%w[new edit])
        end

        def turnstile_failure_action
          action_name == "create" ? :new : :edit
        end
      end
    end
  end
end
