require 'application_system_test_case'

class UnlocksTest < ApplicationSystemTestCase
  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    @user = create_user(email: 'locked@example.com', locked: true)
  end

  test 'resend unlock page renders turnstile widget' do
    visit new_user_unlock_url
    wait_for_turnstile_inputs(1)

    assert_turnstile_widget
  end

  test 'resend unlock with passing turnstile succeeds' do
    visit new_user_unlock_url
    wait_for_turnstile_inputs(1)
    fill_in 'Email', with: @user.email
    click_on 'Resend unlock instructions'

    assert_text(/email with instructions/i)
  end

  test 'resend unlock with failing turnstile shows error and keeps widget' do
    with_failing_turnstile do
      visit new_user_unlock_url
      wait_for_turnstile_inputs(1)
      fill_in 'Email', with: @user.email
      click_on 'Resend unlock instructions'

      assert_text Cloudflare::Turnstile::Rails::ErrorMessage.default
      wait_for_turnstile_inputs(1)
    end
  end
end
