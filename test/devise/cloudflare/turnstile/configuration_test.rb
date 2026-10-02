require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    @config = Cloudflare::Turnstile::Rails::Configuration.new
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

  def test_repeated_skips_for_a_controller_accumulate
    @config.skip passwords: :create
    @config.skip passwords: :new

    assert @config.skipped?('passwords', 'create')
    assert @config.skipped?('passwords', 'new')
    refute @config.skipped?('passwords', 'edit')
  end

  def test_skipping_the_whole_controller_is_not_narrowed_by_a_later_action_skip
    @config.skip :passwords
    @config.skip passwords: :create

    assert @config.skipped?('passwords', 'new')
    assert @config.skipped?('passwords', 'edit')
  end

  def test_skipping_the_whole_controller_widens_an_earlier_action_skip
    @config.skip passwords: :create
    @config.skip :passwords

    assert @config.skipped?('passwords', 'new')
  end

  def test_string_and_symbol_names_are_equivalent
    @config.skip 'sessions' => 'create'

    assert @config.skipped?(:sessions, :create)
  end

  def test_configure_yields_shared_configuration
    Cloudflare::Turnstile::Rails.configure { |config| config.skip :registrations }

    assert Cloudflare::Turnstile::Rails.configuration.skipped?('registrations', 'create')
  ensure
    Cloudflare::Turnstile::Rails.configuration.skips.clear
  end
end
