require 'test_helper'

class UnlocksControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    @user = User.create!(
      email: 'unlock-controller@example.com',
      password: 'Password1!',
      password_confirmation: 'Password1!',
      confirmed_at: Time.now.utc,
      locked_at: Time.now.utc,
      failed_attempts: 10
    )
  end

  test 'GET resend unlock renders turnstile head tags' do
    get new_user_unlock_url

    assert_response :success
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/devise_cloudflare_turnstile/, response.body)
  end

  test 'POST resend unlock with auto-populated turnstile succeeds' do
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_unlock_url, params: { user: { email: @user.email } }

    assert_redirected_to new_user_session_url
  end

  test 'POST resend unlock with failing turnstile re-renders new' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = '2x0000000000000000000000000000000AA'
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_unlock_url, params: { user: { email: @user.email } }

    assert_response :unprocessable_entity
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/We could not verify that you/, response.body)
  end
end
