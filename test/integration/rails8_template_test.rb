require 'test_helper'
require_relative 'template_app_test'

class Rails8TemplateTest < Minitest::Test
  include TemplateAppTest

  def setup
    skip unless RUBY_VERSION >= '3.2.0' && Rails::VERSION::STRING.start_with?('8.')
    setup_template_app
  end

  def teardown
    teardown_template_app
  end

  def test_system_tests_pass_in_rails8_generated_app # rubocop:disable Metrics/MethodLength
    generate_and_test_app(
      rubyopt: '-r logger',
      rails_new_args: %w[
        new . --quiet
        --skip-git --skip-docker --skip-keeps
        --skip-action-mailbox --skip-action-text
        --skip-active-storage
        --skip-action-cable --skip-jbuilder --skip-bootsnap
        --skip-dev-gems --skip-thruster --skip-rubocop --skip-brakeman
        --skip-ci --skip-kamal --skip-solid --skip-devcontainer
        --skip-api --skip-decrypted-diffs
        -d sqlite3
      ],
      test_commands: [
        %w[bin/rails test:all]
      ]
    )
  end
end
