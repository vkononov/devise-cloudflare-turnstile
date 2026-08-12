require 'application_system_test_case'

class InvitationsTest < ApplicationSystemTestCase
  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end

    @inviter = create_user(email: 'inviter@example.com')
  end

  test 'invite page renders turnstile widget when signed in' do
    sign_in_via_form(@inviter)
    visit new_user_invitation_url
    wait_for_turnstile_inputs(1)

    assert_turnstile_widget
  end

  test 'sending invitation with passing turnstile succeeds' do
    sign_in_via_form(@inviter)
    visit new_user_invitation_url
    wait_for_turnstile_inputs(1)
    fill_in 'Email', with: 'invitee@example.com'
    click_on 'Send an invitation'

    assert_text(/invitation|sent/i)
  end

  test 'sending invitation with failing turnstile shows error and keeps widget' do
    sign_in_via_form(@inviter)

    with_failing_turnstile do
      visit new_user_invitation_url
      wait_for_turnstile_inputs(1)
      fill_in 'Email', with: 'blocked-invitee@example.com'
      click_on 'Send an invitation'

      assert_text Cloudflare::Turnstile::Rails::ErrorMessage.default
      wait_for_turnstile_inputs(1)
    end
  end

  # Accept invitation is an update action; only create actions are protected,
  # so no widget is injected on the accept form.
  test 'accept invitation page has no turnstile widget' do
    raw = User.invite!(email: 'accept@example.com', skip_invitation: true).raw_invitation_token
    visit accept_user_invitation_url(invitation_token: raw)

    assert_selector "input[type='password']", visible: :all, wait: 5
    assert_no_selector 'div.cf-turnstile', visible: :all
    assert_no_selector "meta[name='cf-turnstile-site-key']", visible: :all
  end

  private

  def sign_in_via_form(user)
    visit new_user_session_url
    wait_for_turnstile_inputs(1)
    fill_email_and_password(email: user.email)
    click_on 'Log in'

    assert_text 'Signed in successfully'
  end
end
