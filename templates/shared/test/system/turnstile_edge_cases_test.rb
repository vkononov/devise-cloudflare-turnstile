require 'application_system_test_case'

class TurnstileEdgeCasesTest < ApplicationSystemTestCase
  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    @user = create_user(email: 'edge@example.com')
  end

  test 'visiting sign in twice does not render turnstile twice' do
    visit new_user_session_url
    wait_for_turnstile_inputs(1, message: 'after first visit')
    visit new_user_session_url
    wait_for_turnstile_inputs(1, message: 'after second visit')

    assert_selector 'div.cf-turnstile', count: 1, visible: :all
    assert_turnstile_widget
  end

  test 'submitting before turnstile is ready still works with auto populate' do
    visit new_user_session_url
    fill_email_and_password(email: @user.email)
    click_on 'Log in'

    assert_text 'Signed in successfully'
  end

  test 'turnstile does not render when site key is invalid' do
    Cloudflare::Turnstile::Rails.configuration.site_key = 'DUMMY'
    visit new_user_session_url

    assert_no_selector "div.cf-turnstile input[name='cf-turnstile-response']", visible: :all, wait: 5
  end

  test 'turnstile returns an error when secret key is invalid' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = 'DUMMY'
    visit new_user_session_url
    wait_for_turnstile_inputs(1, message: 'after page load')
    fill_email_and_password(email: @user.email)
    click_on 'Log in'

    assert_text Cloudflare::Turnstile::Rails::ErrorMessage.default
    wait_for_turnstile_inputs(1, message: 'after invalid secret')
  end

  test 'turnstile validation fails when the token is expired' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = '3x0000000000000000000000000000000AA'
    visit new_user_session_url
    wait_for_turnstile_inputs(1, message: 'after page load')
    fill_email_and_password(email: @user.email)
    click_on 'Log in'

    assert_text Cloudflare::Turnstile::Rails::ErrorMessage.default
    wait_for_turnstile_inputs(1, message: 'after expired token')
  end

  test 'nonce is propagated from helper script to Cloudflare script' do
    skip 'CSP nonces require Rails 5.2+' if Rails::VERSION::STRING < '5.2'

    visit new_user_session_url
    wait_for_turnstile_inputs(1)

    helper_nonce = evaluate_script(<<~JS)
      (function() {
        var helper = document.querySelector('script[src*="cloudflare_turnstile_helper"]');
        return helper ? helper.nonce : null;
      })()
    JS

    cloudflare_nonce = evaluate_script(<<~JS)
      (function() {
        var cf = document.querySelector('script[src*="challenges.cloudflare.com"]');
        return cf ? cf.nonce : null;
      })()
    JS

    assert_not_nil helper_nonce, 'Helper script should have a nonce attribute'
    assert_not_nil cloudflare_nonce, 'Cloudflare script should have a nonce attribute'
    assert_equal helper_nonce, cloudflare_nonce,
                 'Cloudflare script nonce should match helper script nonce'
  end
end
