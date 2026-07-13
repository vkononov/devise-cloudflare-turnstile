require 'test_helper'
require 'devise/cloudflare/turnstile/engine'

class EngineTest < Minitest::Test
  def setup
    assets = Struct.new(:paths, :precompile).new([], [])
    config = Struct.new(:assets).new(assets)
    @app = Struct.new(:config).new(config)
    @initializer = Devise::Cloudflare::Turnstile::Engine.initializers
                                                        .find { |i| i.name == 'devise_cloudflare_turnstile.assets' }
  end

  def test_initializer_is_defined
    assert @initializer, "Expected initializer 'devise_cloudflare_turnstile.assets'"
  end

  def test_initializer_skips_when_assets_not_configured
    app = Struct.new(:config).new(Object.new)

    assert_nil @initializer.run(app)
  end

  def test_assets_path_is_added
    @initializer.run(@app)
    expected = Devise::Cloudflare::Turnstile::Engine.root.join('app/assets/javascripts')

    assert_includes @app.config.assets.paths, expected
  end

  def test_injector_js_is_precompiled
    @initializer.run(@app)

    assert_includes @app.config.assets.precompile, 'devise_cloudflare_turnstile.js'
  end
end
