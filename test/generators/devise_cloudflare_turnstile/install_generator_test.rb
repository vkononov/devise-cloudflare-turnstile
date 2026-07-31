require 'test_helper'
require 'generators/devise_cloudflare_turnstile/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests DeviseCloudflareTurnstile::InstallGenerator
  destination File.expand_path('../tmp', __dir__)
  setup :prepare_destination

  def test_requires_devise
    assert_raises(SystemExit) { run_generator }
  end

  def test_creates_single_combined_initializer
    prepare_devise

    run_generator

    assert_file 'config/initializers/cloudflare_turnstile.rb' do |content|
      assert_match(/Cloudflare::Turnstile::Rails\.configure do \|config\|/, content)
      assert_match(/config\.site_key/, content)
      assert_match(/config\.secret_key/, content)
      assert_match(/# config\.skip :confirmations/, content)
      refute_match(/Devise::Cloudflare::Turnstile\.configure/, content)
      assert_operator content.index('# config.skip :confirmations'), :<, content.rindex("\nend")
      assert_equal 1, content.scan(/^end$/).size
    end
  end

  def test_overwrite_reproduces_a_clean_single_block
    prepare_devise

    run_generator
    run_generator %w[--force]

    assert_file 'config/initializers/cloudflare_turnstile.rb' do |content|
      assert_equal 1, content.scan('Cloudflare::Turnstile::Rails.configure').size
      assert_equal 1, content.scan('# config.skip :confirmations').size
    end
  end

  def test_leaves_the_layout_untouched
    prepare_devise
    FileUtils.mkdir_p(File.join(destination_root, 'app/views/layouts'))
    layout = "<!DOCTYPE html>\n<html>\n  <head>\n    <title>App</title>\n  </head>\n  <body></body>\n</html>\n"
    File.write(File.join(destination_root, 'app/views/layouts/application.html.erb'), layout)

    run_generator

    assert_file 'app/views/layouts/application.html.erb' do |content|
      assert_equal layout, content
    end
  end

  private

  def prepare_devise
    FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))
    File.write(File.join(destination_root, 'config/initializers/devise.rb'), "# devise\n")
  end
end
