module Devise
  module Cloudflare
    module Turnstile
      class Configuration
        attr_reader :skips

        def initialize
          @skips = {}
        end

        # Registers controllers/actions that should not be protected.
        #
        #   config.skip :confirmations              # every action
        #   config.skip passwords: :create          # a single action
        #   config.skip unlocks: [:new, :create]    # a set of actions
        def skip(*controllers, **controller_actions)
          controllers.each { |controller| @skips[controller.to_s] = :all }

          controller_actions.each do |controller, actions|
            @skips[controller.to_s] = Array(actions).map(&:to_s)
          end
        end

        def skipped?(controller_name, action_name)
          rule = @skips[controller_name.to_s]
          return false if rule.nil?
          return true if rule == :all

          rule.include?(action_name.to_s)
        end
      end
    end
  end
end
