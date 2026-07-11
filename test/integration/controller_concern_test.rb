require 'test_helper'

class ControllerConcernRequestTest < ActionDispatch::IntegrationTest
  include TurnstileRequestHelpers

  def test_new_marks_the_page_and_emits_turnstile_head_tags
    get '/concern/new'

    assert_response :success
    assert_includes @response.body, 'marked:true'
    assert_includes @response.body, 'name="cf-turnstile-site-key"'
    assert_includes @response.body, 'cloudflare_turnstile_helper'
    assert_includes @response.body, 'devise_cloudflare_turnstile'
  end

  def test_edit_marks_the_page
    get '/concern/edit'

    assert_response :success
    assert_includes @response.body, 'marked:true'
  end

  def test_create_is_verified
    with_secret('') do
      assert_raises(Cloudflare::Turnstile::Rails::ConfigurationError) do
        post '/concern'
      end
    end
  end

  def test_new_is_not_verified
    with_secret('') do
      get '/concern/new'

      assert_response :success
    end
  end

  # Turnstile passes and the action re-renders (e.g. Devise validation errors).
  # The create marker must keep meta/scripts in the response for Turbo head merges.
  def test_successful_turnstile_create_still_emits_head_tags
    stub_siteverify(success: true)

    post '/concern'

    assert_response :success
    assert_includes @response.body, 'name="cf-turnstile-site-key"'
    assert_includes @response.body, 'cloudflare_turnstile_helper'
    assert_includes @response.body, 'devise_cloudflare_turnstile'
  end

  def test_failed_turnstile_re_renders_new_with_head_tags
    stub_siteverify(success: false)

    post '/concern'

    assert_response :unprocessable_entity
    assert_includes @response.body, 'marked:true'
    assert_includes @response.body, 'name="cf-turnstile-site-key"'
    assert_includes @response.body, 'devise_cloudflare_turnstile'
  end
end
