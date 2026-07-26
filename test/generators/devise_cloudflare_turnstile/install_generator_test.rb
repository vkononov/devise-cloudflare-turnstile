require 'test_helper'
require 'generators/devise_cloudflare_turnstile/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests DeviseCloudflareTurnstile::InstallGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  def test_requires_devise
    assert_raises(SystemExit) { run_generator }
  end

  def test_creates_initializer
    FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))
    File.write(File.join(destination_root, 'config/initializers/devise.rb'), "# devise\n")

    run_generator

    assert_file 'config/initializers/cloudflare_turnstile.rb' do |content|
      assert_match(/Cloudflare::Turnstile::Rails\.configure/, content)
      assert_match(/config\.site_key/, content)
      assert_match(/config\.secret_key/, content)
    end
  end

  def test_leaves_the_layout_untouched
    FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))
    FileUtils.mkdir_p(File.join(destination_root, 'app/views/layouts'))
    File.write(File.join(destination_root, 'config/initializers/devise.rb'), "# devise\n")
    layout = "<!DOCTYPE html>\n<html>\n  <head>\n    <title>App</title>\n  </head>\n  <body></body>\n</html>\n"
    File.write(File.join(destination_root, 'app/views/layouts/application.html.erb'), layout)

    run_generator

    assert_file 'app/views/layouts/application.html.erb' do |content|
      assert_equal layout, content
    end
  end
end
