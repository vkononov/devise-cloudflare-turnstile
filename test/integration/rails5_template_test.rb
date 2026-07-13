require 'test_helper'
require_relative 'template_app_test'

class Rails5TemplateTest < Minitest::Test
  include TemplateAppTest

  def setup
    # System tests require ActionDispatch::SystemTestCase (Rails 5.1+).
    skip unless RUBY_VERSION < '3.0.0' &&
                Rails::VERSION::STRING.start_with?('5.') &&
                Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('5.1.0')
    setup_template_app
  end

  def teardown
    teardown_template_app
  end

  def test_system_tests_pass_in_rails5_generated_app # rubocop:disable Metrics/MethodLength
    generate_and_test_app(
      rubyopt: '-r logger -r bigdecimal',
      rails_new_args: %w[
        new . --quiet
        --skip-git --skip-keeps
        --skip-active-storage
        --skip-action-cable --skip-spring --skip-listen --skip-coffee
        --skip-bootsnap --skip-api
        -d sqlite3
      ],
      test_commands: [
        %w[bin/rails test],
        %w[bin/rails test:system]
      ]
    )
  end
end
