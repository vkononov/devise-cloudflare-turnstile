require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    @config = Devise::Cloudflare::Turnstile::Configuration.new
  end

  def test_no_skips_by_default
    refute @config.skipped?('sessions', 'create')
  end

  def test_skip_whole_controller
    @config.skip :confirmations

    assert @config.skipped?('confirmations', 'new')
    assert @config.skipped?('confirmations', 'create')
    refute @config.skipped?('sessions', 'create')
  end

  def test_skip_single_action
    @config.skip passwords: :create

    assert @config.skipped?('passwords', 'create')
    refute @config.skipped?('passwords', 'new')
  end

  def test_skip_multiple_actions
    @config.skip unlocks: %i[new create]

    assert @config.skipped?('unlocks', 'new')
    assert @config.skipped?('unlocks', 'create')
    refute @config.skipped?('unlocks', 'edit')
  end

  def test_module_configure_yields_shared_configuration
    Devise::Cloudflare::Turnstile.configure { |c| c.skip :registrations }

    assert Devise::Cloudflare::Turnstile.configuration.skipped?('registrations', 'create')
  ensure
    Devise::Cloudflare::Turnstile.configuration.skips.clear
  end
end
