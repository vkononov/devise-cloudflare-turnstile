require 'cloudflare/turnstile/rails'

# Adds a Devise-aware skip registry to cloudflare-turnstile-rails'
# configuration, so its configure block controls both the widget and which
# Devise controllers/actions to protect.
module Cloudflare
  module Turnstile
    module Rails
      class Configuration
        # The Devise controller actions Turnstile protects. Defaults to the
        # create actions (sign in, sign up, password-reset request, resend
        # confirmation/unlock) which are the unauthenticated entry points. Add
        # 'update' to also cover password-reset completion and account updates.
        def protected_actions
          @protected_actions ||= %w[create]
        end

        def protected_actions=(actions)
          @protected_actions = Array(actions).map(&:to_s)
        end

        def skips
          @skips ||= {}
        end

        # Registers Devise controllers/actions that should not be protected.
        #
        #   config.skip :confirmations            # every action
        #   config.skip passwords: :create        # a single action
        #   config.skip unlocks: [:new, :create]  # a set of actions
        def skip(*controllers, **controller_actions)
          controllers.each { |controller| skips[controller.to_s] = :all }

          controller_actions.each do |controller, actions|
            skips[controller.to_s] = Array(actions).map(&:to_s)
          end
        end

        def skipped?(controller_name, action_name)
          rule = skips[controller_name.to_s]
          return false if rule.nil?
          return true if rule == :all

          rule.include?(action_name.to_s)
        end
      end
    end
  end
end
