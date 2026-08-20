module Devise
  module Cloudflare
    module Turnstile
      module ControllerConcern
        extend ActiveSupport::Concern

        included do
          # class_attribute's `default:` keyword arrived in Rails 5.2, so set it
          # explicitly to keep Rails 5.0/5.1 compatibility.
          class_attribute :_turnstile_skip_rules, instance_accessor: false
          self._turnstile_skip_rules = []

          before_action :verify_cloudflare_turnstile!, if: :turnstile_verify_action?
          before_action :set_turnstile_page_marker, if: :turnstile_form_action?
        end

        module ClassMethods
          # Disables Turnstile for this controller.
          #
          #   skip_turnstile                 # every action
          #   skip_turnstile only: :create   # a subset
          #   skip_turnstile except: :new    # everything but a subset
          def skip_turnstile(only: nil, except: nil)
            self._turnstile_skip_rules += [{
              only: Array(only).map(&:to_s),
              except: Array(except).map(&:to_s)
            }]
          end
        end

        private

        def verify_cloudflare_turnstile! # rubocop:disable Metrics/AbcSize
          return if turnstile_skipped?

          self.resource ||= resource_class.new
          return if turnstile_verified?

          revoke_params_authentication!
          restore_turnstile_submitted_values

          flash.now[:alert] = ::Cloudflare::Turnstile::Rails::ErrorMessage.default
          clean_up_passwords(resource) if respond_to?(:clean_up_passwords, true)
          set_minimum_password_length if respond_to?(:set_minimum_password_length, true)
          set_turnstile_page_marker
          render turnstile_failure_action, status: :unprocessable_entity
        end

        # No model is passed, so the failure stays out of resource.errors.
        # valid_turnstile? is avoided: it sets a flash that outlives this render.
        def turnstile_verified?
          result = verify_turnstile(**turnstile_verify_options)

          result.is_a?(::Cloudflare::Turnstile::Rails::VerificationResponse) && result.success?
        end

        # Devise's sessions#create marks the request eligible for authentication
        # straight from the posted credentials. That flag outlives our halt, so
        # any current_user call during the failure render would sign the visitor
        # in. Devise publishes no constant for the key.
        def revoke_params_authentication!
          request.env.delete('devise.allow_params_authentication')
        end

        # Re-populate the resource with the values the user just submitted (minus
        # passwords) so the re-rendered form keeps their input. We fail in a
        # before_action, before Devise builds the resource from params, so
        # without this the form would come back blank. Assigning to the
        # in-memory resource is safe because the request halts here and the
        # record is never saved.
        def restore_turnstile_submitted_values
          return unless respond_to?(:resource_name, true)

          submitted = params[resource_name]
          return unless submitted.respond_to?(:each_pair)

          submitted.each_pair do |field, value|
            next if field.to_s.include?('password')
            next unless turnstile_scalar_value?(value)

            setter = "#{field}="
            resource.public_send(setter, value) if resource.respond_to?(setter)
          end
        end

        # Limits restoration to simple form values. Nested params (e.g. arrays or
        # *_attributes hashes) are skipped because assigning them to the resource
        # is error-prone, and Devise forms only use scalar fields anyway.
        def turnstile_scalar_value?(value)
          value.is_a?(String) || value.is_a?(Numeric) || [true, false].include?(value)
        end

        # Extra siteverify parameters forwarded to valid_turnstile?. Override in a
        # custom Devise controller to add e.g. remoteip: request.remote_ip.
        def turnstile_verify_options
          {}
        end

        def set_turnstile_page_marker
          @_devise_turnstile_protected = true
        end

        # Verify only on create. Kept as a predicate rather than `only: :create`
        # so the callback is skipped cleanly on controllers without a create
        # action instead of raising.
        def turnstile_verify_action?
          action_name == 'create'
        end

        # The widget shows on the create forms (`new`) and on `create` itself, so
        # a failed submission that re-renders still emits the meta tag and scripts
        # that Turbo needs. Edit/update pages are excluded because only `create`
        # is verified.
        def turnstile_form_action?
          return false if turnstile_skipped?

          action_name.in?(%w[new create])
        end

        def turnstile_skipped?
          return true if ::Cloudflare::Turnstile::Rails.configuration.skipped?(controller_name, action_name)

          self.class._turnstile_skip_rules.any? { |rule| turnstile_rule_matches?(rule) }
        end

        def turnstile_rule_matches?(rule)
          return false if rule[:except].include?(action_name)
          return true if rule[:only].empty?

          rule[:only].include?(action_name)
        end

        def turnstile_failure_action
          action_name.in?(%w[create]) ? :new : :edit
        end
      end
    end
  end
end
