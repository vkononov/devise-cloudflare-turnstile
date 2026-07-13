require 'test_helper'
require_relative 'template_app_test'

class Rails6TemplateTest < Minitest::Test
  include TemplateAppTest

  def setup
    skip unless RUBY_VERSION < '3.4.0' && Rails::VERSION::STRING.start_with?('6.')
    setup_template_app
  end

  def teardown
    teardown_template_app
  end

  def test_system_tests_pass_in_rails6_generated_app # rubocop:disable Metrics/MethodLength
    generate_and_test_app(
      rubyopt: '-r logger -r bigdecimal',
      rails_new_args: %w[
        new . --quiet
        --skip-git --skip-keeps
        --skip-action-mailbox --skip-action-text
        --skip-active-job --skip-active-storage
        --skip-action-cable --skip-spring --skip-listen --skip-jbuilder
        --skip-bootsnap --skip-api
        --skip-webpack-install
        -d sqlite3
      ],
      test_commands: [
        %w[bin/rails test:system],
        %w[bin/rails test]
      ]
    )
  end
end
