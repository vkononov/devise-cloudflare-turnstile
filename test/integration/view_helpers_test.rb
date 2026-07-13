require 'test_helper'

class ViewHelpersTest < ActionDispatch::IntegrationTest
  include TurnstileRequestHelpers

  def test_helpers_render_nothing_on_unprotected_pages
    get '/unprotected'

    assert_response :success
    assert_equal '|', @response.body.strip
  end

  def test_meta_tag_exposes_the_configured_site_key
    get '/protected'

    assert_response :success
    assert_includes @response.body, '<meta name="cf-turnstile-site-key"'
    assert_includes @response.body, 'content="SITEKEY"'
  end

  def test_meta_tag_is_omitted_when_site_key_blank
    with_site_key('') do
      get '/protected'

      assert_response :success
      refute_includes @response.body, 'cf-turnstile-site-key'
      assert_includes @response.body, 'devise_cloudflare_turnstile'
    end
  end

  def test_scripts_load_the_cloudflare_turnstile_rails_runtime
    get '/protected'

    assert_includes @response.body, 'cloudflare_turnstile_helper'
    assert_includes @response.body,
                    'data-script-url="https://challenges.cloudflare.com/turnstile/v0/api.js"'
  end

  def test_scripts_load_the_devise_injector
    get '/protected'

    assert_includes @response.body, 'devise_cloudflare_turnstile'
  end

  def test_scripts_carry_the_csp_nonce
    skip 'CSP nonces require Rails 5.2+' if Rails::VERSION::STRING < '5.2'

    get '/protected'

    nonces = @response.body.scan(/<script[^>]*\bnonce="([^"]+)"/).flatten

    assert_equal 2, nonces.size, 'expected both script tags to carry a nonce'
    assert_equal %w[test-nonce test-nonce], nonces
  end
end
