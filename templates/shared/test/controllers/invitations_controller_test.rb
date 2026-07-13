require 'test_helper'

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    Cloudflare::Turnstile::Rails.configuration.auto_populate_response_in_test_env = true

    @inviter = User.create!(
      email: 'invite-controller@example.com',
      password: 'Password1!',
      password_confirmation: 'Password1!',
      confirmed_at: Time.now.utc
    )

    post user_session_url, params: {
      user: { email: @inviter.email, password: 'Password1!' }
    }
  end

  test 'GET invite renders turnstile head tags' do
    get new_user_invitation_url

    assert_response :success
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/devise_cloudflare_turnstile/, response.body)
  end

  test 'POST invite with auto-populated turnstile succeeds' do
    assert_difference('User.count', 1) do
      post user_invitation_url, params: { user: { email: 'invitee-controller@example.com' } }
    end
  end

  test 'POST invite with failing turnstile re-renders new' do
    Cloudflare::Turnstile::Rails.configuration.secret_key = '2x0000000000000000000000000000000AA'

    assert_no_difference('User.count') do
      post user_invitation_url, params: { user: { email: 'blocked-invitee-controller@example.com' } }
    end

    assert_response :unprocessable_entity
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/We could not verify that you/, response.body)
  end

  test 'GET accept invitation renders turnstile head tags' do
    raw = User.invite!(email: 'accept-controller@example.com', skip_invitation: true).raw_invitation_token
    get accept_user_invitation_url(invitation_token: raw)

    assert_response :success
    assert_match(/cf-turnstile-site-key/, response.body)
    assert_match(/devise_cloudflare_turnstile/, response.body)
  end
end
