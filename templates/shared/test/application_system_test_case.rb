require 'test_helper'
require 'support/turnstile_system_helpers'
require 'support/devise_system_helpers'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include TurnstileSystemHelpers
  include DeviseSystemHelpers

  BROWSER = ENV.fetch('BROWSER', 'chrome').to_sym

  driven_by :selenium, using: :"headless_#{BROWSER}", screen_size: [1400, 1400]
end
