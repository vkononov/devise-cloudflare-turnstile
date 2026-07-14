require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    @user = User.create!(
      email: 'password-controller@example.com',
      password: 'Password1!',
      password_confirmation: 'Password1!',
      confirmed_at: Time.now.utc
    )
  end

  test 'GET forgot password renders turnstile head tags' do
    get new_user_password_url

    assert_response :success
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/devise_cloudflare_turnstile/, response.body)
  end

  test 'POST forgot password with auto-populated turnstile succeeds' do
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_password_url, params: { user: { email: @user.email } }

    assert_redirected_to new_user_session_url
  end

  test 'POST forgot password with failing turnstile re-renders new' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = '2x0000000000000000000000000000000AA'
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_password_url, params: { user: { email: @user.email } }

    assert_response :unprocessable_entity
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/We could not verify that you/, response.body)
  end
end
