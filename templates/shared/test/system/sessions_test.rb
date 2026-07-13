require 'application_system_test_case'

class SessionsTest < ApplicationSystemTestCase
  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    @user = create_user(email: 'session@example.com')
  end

  test 'sign in page renders turnstile widget' do
    visit new_user_session_url
    wait_for_turnstile_inputs(1)

    assert_turnstile_widget
  end

  test 'sign in with passing turnstile succeeds' do
    visit new_user_session_url
    wait_for_turnstile_inputs(1)
    fill_email_and_password(email: @user.email)
    click_on 'Log in'

    assert_text 'Signed in successfully'
  end

  test 'sign in with failing turnstile shows error and keeps widget' do
    with_failing_turnstile do
      visit new_user_session_url
      wait_for_turnstile_inputs(1)
      fill_email_and_password(email: @user.email)
      click_on 'Log in'

      assert_text Cloudflare::Turnstile::Rails::ErrorMessage.default
      wait_for_turnstile_inputs(1)
    end
  end

  test 'navigating from home to sign in still renders widget' do
    visit root_url
    click_on 'Sign in'
    wait_for_turnstile_inputs(1)

    assert_turnstile_widget
  end
end
