require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    @config = Cloudflare::Turnstile::Rails::Configuration.new
  end

  def test_no_skips_by_default
    refute @config.skipped?('sessions', 'create')
  end

  def test_protected_actions_default_to_create
    assert_equal %w[create], @config.protected_actions
  end

  def test_protected_actions_setter_normalizes_to_strings
    @config.protected_actions = %i[create update]

    assert_equal %w[create update], @config.protected_actions
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

  def test_configure_yields_shared_configuration
    Cloudflare::Turnstile::Rails.configure { |config| config.skip :registrations }

    assert Cloudflare::Turnstile::Rails.configuration.skipped?('registrations', 'create')
  ensure
    Cloudflare::Turnstile::Rails.configuration.skips.clear
  end
end
