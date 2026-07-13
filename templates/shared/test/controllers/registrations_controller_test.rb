require 'test_helper'

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end
  end

  test 'GET sign up renders turnstile head tags' do
    get new_user_registration_url

    assert_response :success
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/devise_cloudflare_turnstile/, response.body)
  end

  test 'POST sign up with auto-populated turnstile succeeds' do
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    assert_difference('User.count', 1) do
      post user_registration_url, params: {
        user: {
          email: 'controller-signup@example.com',
          password: 'Password1!',
          password_confirmation: 'Password1!'
        }
      }
    end
  end

  test 'POST sign up with failing turnstile re-renders new' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = '2x0000000000000000000000000000000AA'
    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    assert_no_difference('User.count') do
      post user_registration_url, params: {
        user: {
          email: 'blocked-signup@example.com',
          password: 'Password1!',
          password_confirmation: 'Password1!'
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/We could not verify that you/, response.body)
  end
end
