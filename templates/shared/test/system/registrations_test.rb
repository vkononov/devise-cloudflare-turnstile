require 'application_system_test_case'

class RegistrationsTest < ApplicationSystemTestCase
  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end
  end

  test 'sign up page renders turnstile widget' do
    visit new_user_registration_url
    wait_for_turnstile_inputs(1)

    assert_turnstile_widget
  end

  test 'sign up with passing turnstile succeeds' do
    visit new_user_registration_url
    wait_for_turnstile_inputs(1)
    fill_in 'Email', with: 'newuser@example.com'
    fill_in 'Password', with: PASSWORD
    fill_in 'Password confirmation', with: PASSWORD
    click_on 'Sign up'

    assert_text(/confirmation|signed up|welcome/i)
  end

  test 'sign up validation error re-renders form with widget' do
    visit new_user_registration_url
    wait_for_turnstile_inputs(1)
    fill_in 'Email', with: 'invalid'
    fill_in 'Password', with: ''
    fill_in 'Password confirmation', with: ''
    click_on 'Sign up'

    wait_for_turnstile_inputs(1)

    assert_turnstile_widget
  end

  test 'sign up with failing turnstile shows error and keeps widget' do
    with_failing_turnstile do
      visit new_user_registration_url
      wait_for_turnstile_inputs(1)
      fill_in 'Email', with: 'blocked@example.com'
      fill_in 'Password', with: PASSWORD
      fill_in 'Password confirmation', with: PASSWORD
      click_on 'Sign up'

      assert_text Cloudflare::Turnstile::Rails::ErrorMessage.default
      wait_for_turnstile_inputs(1)
    end
  end

  test 'failing turnstile re-renders the form with the submitted email preserved' do
    with_failing_turnstile do
      visit new_user_registration_url
      wait_for_turnstile_inputs(1)
      fill_in 'Email', with: 'preserve@example.com'
      fill_in 'Password', with: PASSWORD
      fill_in 'Password confirmation', with: PASSWORD
      click_on 'Sign up'

      assert_text Cloudflare::Turnstile::Rails::ErrorMessage.default
      assert_field 'Email', with: 'preserve@example.com'
      assert_field 'Password', with: ''
    end
  end
end
