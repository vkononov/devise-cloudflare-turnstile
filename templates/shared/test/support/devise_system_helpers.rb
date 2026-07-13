module DeviseSystemHelpers
  PASSWORD = 'Password1!'.freeze

  def create_user(email:, password: PASSWORD, confirmed: true, locked: false)
    user = User.new(email: email, password: password, password_confirmation: password)
    user.skip_confirmation! if confirmed && user.respond_to?(:skip_confirmation!)
    user.confirmed_at = Time.now.utc if confirmed && user.confirmed_at.blank?
    if locked
      user.locked_at = Time.now.utc
      user.failed_attempts = 10
    end
    user.save!
    user
  end

  def fill_email_and_password(email:, password: PASSWORD)
    fill_in 'Email', with: email
    fill_in 'Password', with: password
  end

  def click_forgot_password_submit
    find('form input[type="submit"]').click
  end

  def assert_turnstile_widget
    assert_selector "div.cf-turnstile input[name='cf-turnstile-response']", count: 1, visible: :all
  end

  def with_failing_turnstile
    original = Cloudflare::Turnstile::Rails.configuration.secret_key
    Cloudflare::Turnstile::Rails.configuration.secret_key = '2x0000000000000000000000000000000AA'
    yield
  ensure
    Cloudflare::Turnstile::Rails.configuration.secret_key = original
  end
end
