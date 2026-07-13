require 'application_system_test_case'

class InjectorBehaviorsTest < ApplicationSystemTestCase
  setup do
    Cloudflare::Turnstile::Rails.configure do |config|
      config.site_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SITE_KEY', '1x00000000000000000000AA')
      config.secret_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY', '1x0000000000000000000000000000000AA')
    end
  end

  test 'injector renders widgets on two forms' do
    skip "Not supported in Github actions for Ruby v#{RUBY_VERSION}" if RUBY_VERSION < '2.7.0' && ENV['CI']

    visit dual_forms_url
    wait_for_turnstile_inputs(2, message: 'after page load')

    assert_selector 'form#form-one div.cf-turnstile', count: 1, visible: :all
    assert_selector 'form#form-two div.cf-turnstile', count: 1, visible: :all
  end

  test 'turbolinks AJAX cache updates page when server returns HTML for remote form' do # rubocop:disable Metrics/BlockLength
    skip 'Turbolinks not available' unless turbolinks_available?

    visit new_user_session_url
    wait_for_turnstile_inputs(1, message: 'after page load')

    listener_registered = evaluate_script(<<~JS)
      (function() {
        return typeof Turbolinks !== 'undefined' &&
               typeof Turbolinks.Snapshot !== 'undefined' &&
               typeof Turbolinks.Snapshot.wrap === 'function';
      })()
    JS
    assert listener_registered, 'Turbolinks.Snapshot.wrap should be available for AJAX cache'

    evaluate_script(<<~JS)
      (function() {
        var testHtml = '<html><head></head><body>' +
          '<div class="test-marker">AJAX Cache Test Marker</div>' +
          '<form method="post">' +
          '<div class="cf-turnstile" data-sitekey="test"></div>' +
          '<input type="submit" value="Log in">' +
          '</form></body></html>';

        var mockXhr = {
          getResponseHeader: function(name) {
            return name === 'Content-Type' ? 'text/html; charset=utf-8' : null;
          },
          response: testHtml
        };

        document.dispatchEvent(new CustomEvent('ajax:complete', {
          bubbles: true,
          detail: [mockXhr]
        }));

        return true;
      })()
    JS

    assert_selector '.test-marker', text: 'AJAX Cache Test Marker', wait: 2
  end

  test 'turbo before-stream-render re-injects widgets into new forms' do
    skip 'Turbo not available' unless turbo_available?

    visit new_user_session_url
    wait_for_turnstile_inputs(1, message: 'after page load')

    widget_count = evaluate_script(<<~JS)
      (function() {
        var detail = {
          render: function() {
            var form = document.createElement('form');
            form.method = 'post';
            form.id = 'stream-injected-form';
            form.innerHTML = '<input type="submit" value="Stream submit">';
            document.body.appendChild(form);
          }
        };

        document.dispatchEvent(new CustomEvent('turbo:before-stream-render', {
          bubbles: true,
          detail: detail
        }));
        detail.render();

        return document.querySelectorAll('div.cf-turnstile').length;
      })()
    JS

    assert_operator widget_count, :>=, 2
    assert_selector 'form#stream-injected-form div.cf-turnstile', count: 1, visible: :all
  end

  private

  def turbolinks_available?
    evaluate_script('typeof Turbolinks !== "undefined"')
  rescue StandardError
    false
  end

  def turbo_available?
    evaluate_script('typeof Turbo !== "undefined"')
  rescue StandardError
    false
  end
end
