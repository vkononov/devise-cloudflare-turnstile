require 'application_system_test_case'

class WidgetCustomizationTest < ApplicationSystemTestCase
  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end
  end

  teardown do
    Cloudflare::Turnstile::Rails.configuration.default_data = {}
    Devise::Cloudflare::Turnstile.configuration.skips.clear
  end

  test 'default data attributes are applied to auto-injected widgets' do
    skip "Not supported in Github actions for Ruby v#{RUBY_VERSION}" if RUBY_VERSION < '2.7.0' && ENV['CI']
    Cloudflare::Turnstile::Rails.configuration.default_data = { theme: 'dark' }

    visit widget_custom_url
    wait_for_turnstile_inputs(2, message: 'after page load')

    assert_selector "form#form-plain div.cf-turnstile[data-theme='dark']", count: 1, visible: :all
  end

  test 'a manual widget keeps its own attributes and is not double-injected' do
    skip "Not supported in Github actions for Ruby v#{RUBY_VERSION}" if RUBY_VERSION < '2.7.0' && ENV['CI']
    Cloudflare::Turnstile::Rails.configuration.default_data = { theme: 'dark' }

    visit widget_custom_url
    wait_for_turnstile_inputs(2, message: 'after page load')

    assert_selector 'form#form-manual div.cf-turnstile', count: 1, visible: :all
    assert_selector "form#form-manual div.cf-turnstile[data-theme='light']", count: 1, visible: :all
  end

  test 'a skipped devise controller renders no widget' do
    Devise::Cloudflare::Turnstile.configure { |config| config.skip :sessions }

    visit new_user_session_url

    assert_no_selector 'div.cf-turnstile', visible: :all, wait: 5
    assert_no_selector "meta[name='cf-turnstile-site-key']", visible: :all
  end
end
