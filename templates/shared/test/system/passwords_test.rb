require 'application_system_test_case'

class PasswordsTest < ApplicationSystemTestCase
  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    @user = create_user(email: 'reset@example.com')
  end

  test 'forgot password page renders turnstile widget' do
    visit new_user_password_url
    wait_for_turnstile_inputs(1)

    assert_turnstile_widget
  end

  test 'forgot password with passing turnstile succeeds' do
    visit new_user_password_url
    wait_for_turnstile_inputs(1)
    fill_in 'Email', with: @user.email
    click_forgot_password_submit

    assert_text(/email with instructions/i)
  end

  test 'forgot password with failing turnstile shows error and keeps widget' do
    with_failing_turnstile do
      visit new_user_password_url
      wait_for_turnstile_inputs(1)
      fill_in 'Email', with: @user.email
      click_forgot_password_submit

      assert_text Cloudflare::Turnstile::Rails::ErrorMessage.default
      wait_for_turnstile_inputs(1)
    end
  end

  # Password reset completion is an update action; only create actions are
  # protected, so no widget is injected on the edit form.
  test 'reset password edit page has no turnstile widget' do
    raw = @user.send(:set_reset_password_token)
    visit edit_user_password_url(reset_password_token: raw)

    assert_selector "input[type='password']", visible: :all, wait: 5
    assert_no_selector 'div.cf-turnstile', visible: :all
    assert_no_selector "meta[name='cf-turnstile-site-key']", visible: :all
  end
end
