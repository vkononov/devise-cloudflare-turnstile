require 'test_helper'
require 'devise/cloudflare/turnstile/railtie'

class RailtieTest < ActiveSupport::TestCase
  setup do
    Devise::Cloudflare::Turnstile::Railtie.initializers.each { |initializer| initializer.run(nil) }
  end

  test 'defines controller_concern initializer' do
    names = Devise::Cloudflare::Turnstile::Railtie.initializers.map(&:name)

    assert_includes names, 'devise_cloudflare_turnstile.controller_concern'
  end

  test 'defines view_helpers initializer' do
    names = Devise::Cloudflare::Turnstile::Railtie.initializers.map(&:name)

    assert_includes names, 'devise_cloudflare_turnstile.view_helpers'
  end

  test 'ControllerConcern is mixed into DeviseController when loaded' do
    devise_controller = Class.new(ActionController::Base)
    ActiveSupport.run_load_hooks(:devise_controller, devise_controller)

    assert_includes devise_controller.included_modules, Devise::Cloudflare::Turnstile::ControllerConcern
  end

  test 'ViewHelpers are mixed into ActionView::Base when loaded' do
    ActiveSupport.run_load_hooks(:action_view, ActionView::Base)

    assert_includes ActionView::Base.included_modules, Devise::Cloudflare::Turnstile::ViewHelpers
  end
end
