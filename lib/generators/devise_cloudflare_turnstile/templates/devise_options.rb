# Choose which Devise controller actions Turnstile protects. Defaults to the
# create actions (sign in, sign up, password-reset request, resend
# confirmation/unlock) - the unauthenticated entry points. Add 'update' to also
# protect password-reset completion and account updates.
# config.protected_actions = %w[create update]

# Disable Turnstile for specific Devise controllers or actions.
# config.skip :confirmations            # every action
# config.skip passwords: :create        # a single action
# config.skip unlocks: [:new, :create]  # a set of actions
