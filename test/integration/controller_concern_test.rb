require 'test_helper'

class ControllerConcernRequestTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  include TurnstileRequestHelpers

  def setup
    DummyResource.clean_up_calls = 0
  end

  def test_new_marks_the_page_and_emits_turnstile_head_tags
    get '/concern/new'

    assert_response :success
    assert_includes @response.body, 'marked:true'
    assert_includes @response.body, 'name="cf-turnstile-site-key"'
    assert_includes @response.body, 'cloudflare_turnstile_helper'
    assert_includes @response.body, 'devise_cloudflare_turnstile'
  end

  def test_edit_not_marked_by_default
    get '/concern/edit'

    assert_response :success
    refute_includes @response.body, 'marked:true'
    refute_includes @response.body, 'cf-turnstile-site-key'
  end

  def test_edit_marks_the_page_when_update_is_protected
    with_protected_actions(%w[create update]) do
      get '/concern/edit'

      assert_response :success
      assert_includes @response.body, 'marked:true'
      assert_includes @response.body, 'name="cf-turnstile-site-key"'
    end
  end

  def test_controller_without_create_action_does_not_raise
    get '/omniauth_like'

    assert_response :success
    assert_equal 'ok', @response.body
  end

  def test_update_is_not_verified_by_default
    with_secret('') do
      patch '/concern'

      assert_response :success
      refute_includes @response.body, 'marked:true'
    end
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
    stub_verification(success: true) do
      post '/concern'

      assert_response :success
      assert_includes @response.body, 'name="cf-turnstile-site-key"'
      assert_includes @response.body, 'cloudflare_turnstile_helper'
      assert_includes @response.body, 'devise_cloudflare_turnstile'
    end
  end

  def test_failed_turnstile_re_renders_new_with_flash_and_head_tags
    stub_verification(success: false) do
      post '/concern'

      assert_response :unprocessable_entity
      assert_includes @response.body, 'marked:true'
      assert_match(/alert:We could not verify that you/, @response.body)
      assert_includes @response.body, 'pwdlen:true'
      assert_includes @response.body, 'name="cf-turnstile-site-key"'
      assert_includes @response.body, 'devise_cloudflare_turnstile'
      assert_operator DummyResource.clean_up_calls, :>=, 1
    end
  end

  def test_failed_turnstile_preserves_submitted_values_except_password_family
    submitted = {
      email: 'keep@example.com', name: 'Ada',
      password: 'topsecret', password_confirmation: 'topsecret', current_password: 'topsecret'
    }

    stub_verification(success: false) do
      post '/concern', params: { dummy_resource: submitted }

      assert_response :unprocessable_entity
      assert_includes @response.body, 'email:keep@example.com|name:Ada|pwd:|pwdconf:|curpwd:|'
      refute_includes @response.body, 'topsecret'
    end
  end

  def test_failed_turnstile_ignores_non_scalar_and_unknown_fields
    submitted = { email: 'ok@example.com', name: { nested: 'x' }, roles: %w[a b], nickname: 'no-setter' }

    stub_verification(success: false) do
      post '/concern', params: { dummy_resource: submitted }

      assert_response :unprocessable_entity
      assert_includes @response.body, 'email:ok@example.com'
      assert_includes @response.body, 'name:|'
    end
  end

  def test_failed_turnstile_on_update_re_renders_edit
    with_protected_actions(%w[create update]) do
      stub_verification(success: false) do
        patch '/concern'

        assert_response :unprocessable_entity
        assert_includes @response.body, 'marked:true'
        assert_includes @response.body, 'action:edit'
        assert_match(/alert:We could not verify that you/, @response.body)
        assert_includes @response.body, 'name="cf-turnstile-site-key"'
      end
    end
  end

  def test_failed_turnstile_on_update_preserves_submitted_values
    with_protected_actions(%w[create update]) do
      stub_verification(success: false) do
        patch '/concern', params: {
          dummy_resource: { email: 'edit@example.com', current_password: 'oldsecret' }
        }

        assert_response :unprocessable_entity
        assert_includes @response.body, 'action:edit'
        assert_includes @response.body, 'email:edit@example.com'
        refute_includes @response.body, 'oldsecret'
      end
    end
  end

  def test_config_skip_action_suppresses_verification
    with_devise_skip(concern_test: :create) do
      with_secret('') do
        post '/concern'

        assert_response :success
      end
    end
  end

  def test_config_skip_action_suppresses_page_marker
    with_devise_skip(concern_test: :new) do
      get '/concern/new'

      assert_response :success
      refute_includes @response.body, 'marked:true'
    end
  end

  def test_macro_skip_all_suppresses_marker_and_verification
    with_secret('') do
      get '/skip_all/new'

      assert_response :success
      refute_includes @response.body, 'cf-turnstile-site-key'

      post '/skip_all'

      assert_response :success
    end
  end

  def test_macro_skip_only_create_leaves_other_actions_protected
    with_secret('') do
      get '/skip_only/new'

      assert_response :success
      assert_includes @response.body, 'cf-turnstile-site-key'

      post '/skip_only'

      assert_response :success
    end
  end

  def test_macro_skip_except_create_still_verifies_create
    get '/skip_except/new'

    assert_response :success
    refute_includes @response.body, 'cf-turnstile-site-key'

    with_secret('') do
      assert_raises(Cloudflare::Turnstile::Rails::ConfigurationError) do
        post '/skip_except'
      end
    end
  end

  def test_verify_options_are_forwarded_to_verification
    captured = capture_turnstile_verify_args { post '/verify_options' }

    assert_equal '9.9.9.9', captured[:remoteip]
  end
end
