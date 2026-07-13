require 'test_helper'
require_relative 'template_app_test'

class Rails7TemplateTest < Minitest::Test
  include TemplateAppTest

  def setup
    ruby_ok = RUBY_VERSION >= '3.1.0' && Rails::VERSION::STRING.start_with?('7.2')
    ruby_legacy_ok = RUBY_VERSION >= '2.7.0' && Rails::VERSION::STRING.start_with?(*%w[7.0 7.1])
    skip unless ruby_ok || ruby_legacy_ok

    setup_template_app
  end

  def teardown
    teardown_template_app
  end

  def test_system_tests_pass_in_rails7_generated_app # rubocop:disable Metrics/MethodLength
    generate_and_test_app(
      rubyopt: '-r logger',
      rails_new_args: %w[
        new . --quiet
        --skip-git --skip-keeps
        --skip-action-mailbox --skip-action-text
        --skip-active-storage
        --skip-action-cable --skip-jbuilder --skip-bootsnap --skip-api
        -d sqlite3
      ],
      test_commands: [
        %w[bin/rails test:all]
      ]
    )
  end
end
