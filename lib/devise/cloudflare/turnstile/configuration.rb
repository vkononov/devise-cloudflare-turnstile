require 'cloudflare/turnstile/rails'

# Adds a Devise-aware skip registry to cloudflare-turnstile-rails'
# configuration, so its configure block controls both the widget and which
# Devise controllers/actions to protect.
module Cloudflare
  module Turnstile
    module Rails
      class Configuration
        def skips
          @skips ||= {}
        end

        # Registers Devise controllers/actions that should not be protected.
        # Repeated calls for the same controller accumulate.
        #
        #   config.skip :confirmations            # every action
        #   config.skip passwords: :create        # a single action
        #   config.skip unlocks: [:new, :create]  # a set of actions
        def skip(*controllers, **controller_actions)
          controllers.each { |controller| skips[controller.to_s] = :all }
          controller_actions.each { |controller, actions| skip_actions(controller.to_s, actions) }
        end

        def skipped?(controller_name, action_name)
          rule = skips[controller_name.to_s]
          return false if rule.nil?
          return true if rule == :all

          rule.include?(action_name.to_s)
        end

        private

        def skip_actions(controller, actions)
          return if skips[controller] == :all

          skips[controller] = Array(skips[controller]) | Array(actions).map(&:to_s)
        end
      end
    end
  end
end
