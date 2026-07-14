require 'test_helper'
require 'generators/devise_cloudflare_turnstile/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests DeviseCloudflareTurnstile::InstallGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  def test_requires_devise
    assert_raises(SystemExit) { run_generator }
  end

  def test_creates_initializer_and_injects_layout_helpers # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))
    FileUtils.mkdir_p(File.join(destination_root, 'app/views/layouts'))
    File.write(File.join(destination_root, 'config/initializers/devise.rb'), "# devise\n")
    File.write(
      File.join(destination_root, 'app/views/layouts/application.html.erb'),
      "<!DOCTYPE html>\n<html>\n  <head>\n    <title>App</title>\n  </head>\n  <body></body>\n</html>\n"
    )

    run_generator

    assert_file 'config/initializers/cloudflare_turnstile.rb' do |content|
      assert_match(/Cloudflare::Turnstile::Rails\.configure/, content)
      assert_match(/config\.site_key/, content)
      assert_match(/config\.secret_key/, content)
    end

    assert_file 'app/views/layouts/application.html.erb' do |content|
      assert_match(/devise_turnstile_meta_tag/, content)
      assert_match(/devise_turnstile_scripts/, content)
    end
  end

  def test_skips_layout_injection_when_already_configured # rubocop:disable Metrics/AbcSize
    FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))
    FileUtils.mkdir_p(File.join(destination_root, 'app/views/layouts'))
    File.write(File.join(destination_root, 'config/initializers/devise.rb'), "# devise\n")
    File.write(
      File.join(destination_root, 'app/views/layouts/application.html.erb'),
      "<head>\n    <%= devise_turnstile_meta_tag %>\n</head>\n"
    )

    run_generator

    assert_file 'app/views/layouts/application.html.erb' do |content|
      assert_equal 1, content.scan('devise_turnstile_meta_tag').size
    end
  end

  def test_skips_layout_injection_when_layout_missing
    FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))
    File.write(File.join(destination_root, 'config/initializers/devise.rb'), "# devise\n")

    run_generator

    assert_file 'config/initializers/cloudflare_turnstile.rb'
    assert_no_file 'app/views/layouts/application.html.erb'
  end
end
