require 'test_helper'

class ControllerConcernRequestTest < ActionDispatch::IntegrationTest
  include TurnstileConfig

  def test_new_action_is_marked_for_turnstile_without_verifying
    get '/concern/new'

    assert_response :success
    assert_equal 'new:true', @response.body
  end

  def test_edit_action_is_marked_for_turnstile
    get '/concern/edit'

    assert_response :success
    assert_equal 'edit:true', @response.body
  end

  # An unconfigured secret makes verification fail fast (before any network
  # call), which lets us prove which actions verification is wired to without
  # contacting Cloudflare.
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

  # Failed create re-renders the form; the marker must still be set so the
  # layout keeps emitting the Turnstile meta/scripts for Turbo head merges.
  def test_failed_create_still_emits_turnstile_head_tags
    post '/concern'

    assert_response :success
    assert_includes @response.body, 'name="cf-turnstile-site-key"'
    assert_includes @response.body, 'cloudflare_turnstile_helper'
    assert_includes @response.body, 'devise_cloudflare_turnstile'
  end
end

class ControllerConcernUnitTest < Minitest::Test
  def test_verification_is_registered_as_a_before_action
    assert_includes before_filters, :verify_cloudflare_turnstile!
  end

  def test_page_marker_is_registered_as_a_before_action
    assert_includes before_filters, :set_turnstile_page_marker
  end

  def test_failure_re_renders_new_for_create
    assert_equal :new, controller_for('create').send(:turnstile_failure_action)
  end

  def test_failure_re_renders_edit_for_non_create
    assert_equal :edit, controller_for('update').send(:turnstile_failure_action)
  end

  def test_form_actions_include_create_and_update_for_failed_rerenders
    assert controller_for('new').send(:turnstile_form_action?)
    assert controller_for('edit').send(:turnstile_form_action?)
    assert controller_for('create').send(:turnstile_form_action?)
    assert controller_for('update').send(:turnstile_form_action?)
    refute controller_for('destroy').send(:turnstile_form_action?)
  end

  def test_page_marker_sets_the_protection_flag
    controller = controller_for('new')

    refute controller.instance_variable_get(:@_devise_turnstile_protected)

    controller.send(:set_turnstile_page_marker)

    assert controller.instance_variable_get(:@_devise_turnstile_protected)
  end

  private

  def before_filters
    ConcernTestController._process_action_callbacks
                         .select { |callback| callback.kind == :before }
                         .map(&:filter)
  end

  def controller_for(action)
    ConcernTestController.new.tap do |controller|
      controller.instance_variable_set(:@_action_name, action)
    end
  end
end
