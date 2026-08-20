require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    @user = User.create!(
      email: 'controller@example.com',
      password: 'Password1!',
      password_confirmation: 'Password1!',
      confirmed_at: Time.now.utc
    )
  end

  test 'GET sign in renders turnstile widget container after scripts load path' do
    get new_user_session_url

    assert_response :success
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/devise_cloudflare_turnstile/, response.body)
  end

  test 'POST sign in with auto-populated turnstile succeeds' do
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_session_url, params: {
      user: { email: @user.email, password: 'Password1!' }
    }

    assert_redirected_to root_url
  end

  test 'POST sign in with failing turnstile re-renders new' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = '2x0000000000000000000000000000000AA'
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_session_url, params: {
      user: { email: @user.email, password: 'Password1!' }
    }

    assert_response :unprocessable_entity
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/We could not verify that you/, response.body)
  end

  test 'POST sign in with failing turnstile does not sign the user in' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = '2x0000000000000000000000000000000AA'
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_session_url, params: {
      user: { email: @user.email, password: 'Password1!' }
    }

    assert_response :unprocessable_entity
    assert_no_match(/id="current-user"/, response.body)

    get root_url

    assert_response :success
    assert_no_match(/id="current-user"/, response.body)
  end

  test 'POST sign in with failing turnstile sets no remember cookie' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = '2x0000000000000000000000000000000AA'
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_session_url, params: {
      user: { email: @user.email, password: 'Password1!', remember_me: '1' }
    }

    assert_response :unprocessable_entity
    assert_nil cookies['remember_user_token'].presence
  end

  test 'POST sign in with passing turnstile still authenticates from params' do
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    post user_session_url, params: {
      user: { email: @user.email, password: 'Password1!' }
    }

    assert_redirected_to root_url
    follow_redirect!

    assert_match(/id="current-user"/, response.body)
    assert_match(/#{Regexp.escape(@user.email)}/, response.body)
  end
end
