require 'bundler'
require 'fileutils'

module TemplateAppTest
  TEMPLATE = File.expand_path('../../templates/template.rb', __dir__)
  TURBOLINKS_AJAX_CACHE = File.expand_path(
    '../../templates/shared/cloudflare_turbolinks_ajax_cache.js', __dir__
  )

  def setup_template_app
    @tmpdir = Dir.mktmpdir('devise_cf_turnstile')
  end

  def teardown_template_app
    # Firefox/geckodriver can leave zombies after marionette crashes; subsequent
    # appraisals then fail with InvalidSessionIdError / decode errors.
    if ENV['CI'] && ENV.fetch('BROWSER', 'chrome') == 'firefox'
      system('pkill -9 -f "(firefox|geckodriver)" >/dev/null 2>&1 || true')
    end

    return unless instance_variable_defined?(:@tmpdir) && Dir.exist?(@tmpdir)

    screenshots_path = File.join(@tmpdir, 'tmp', 'screenshots')
    if Dir.exist?(screenshots_path)
      dest_dir = '/tmp/screenshots'
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp_r("#{screenshots_path}/.", dest_dir)
      puts "Screenshots copied to #{dest_dir}"
    end

    FileUtils.remove_entry(@tmpdir)
  end

  def generate_and_test_app(rails_new_args:, rubyopt:, test_commands:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    devise_version = Gem.loaded_specs.fetch('devise').version.to_s
    invitable_version = Gem.loaded_specs.fetch('devise_invitable').version.to_s

    original_rubyopt = ENV.fetch('RUBYOPT', nil)
    ENV['RUBYOPT'] = rubyopt
    ENV['DEVISE_VERSION'] = devise_version
    ENV['DEVISE_INVITABLE_VERSION'] = invitable_version

    # Generate with the appraisal's Rails (bundle exec), not an unbundled
    # `load` of the railties exe — that activates the newest Rails on GEM_PATH.
    Dir.chdir(@tmpdir) do
      args = rails_new_args + ['-m', TEMPLATE]

      assert system('bundle', 'exec', 'rails', *args),
             "`rails new` failed: rails #{args.join(' ')}"
    end

    Bundler.with_unbundled_env do
      ENV['RUBYOPT'] = rubyopt
      ENV['DEVISE_VERSION'] = devise_version
      ENV['DEVISE_INVITABLE_VERSION'] = invitable_version

      Dir.chdir(@tmpdir) do
        assert system('bundle', 'install', '--quiet'),
               '`bundle install` failed in generated app'

        install_webpacker_if_needed!

        db_cmd = if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('6.0.0')
                   %w[bin/rails db:prepare]
                 else
                   %w[bin/rails db:migrate]
                 end

        assert system(*db_cmd), "`#{db_cmd.join(' ')}` failed in generated app"

        Array(test_commands).each do |command|
          assert system(*command), "`#{command.join(' ')}` failed in generated app"
        end
      end
    end
  ensure
    ENV['RUBYOPT'] = original_rubyopt
  end

  # `bundle exec rails new` keeps BUNDLE_GEMFILE on the appraisal, so Rails 6's
  # post-generate `webpacker:install` cannot see the gem. Skip it during
  # `rails new`, then install against the app bundle here.
  def install_webpacker_if_needed!
    return unless File.read('Gemfile').match?(/gem ['"]webpacker['"]/)

    assert system(webpacker_install_env, 'bin/rails', 'webpacker:install'),
           '`webpacker:install` failed in generated app'

    restore_turbolinks_ajax_cache_pack!
  end

  def webpacker_install_env
    compat = File.expand_path('../support/ruby32_file_dir_exists_compat.rb', __dir__)
    return {} unless File.exist?(compat)

    { 'RUBYOPT' => "#{ENV.fetch('RUBYOPT', '')} -r#{compat}".strip }
  end

  def restore_turbolinks_ajax_cache_pack!
    packer_js = 'app/javascript/packs/application.js'
    return unless File.exist?(packer_js) && File.exist?(TURBOLINKS_AJAX_CACHE)

    FileUtils.cp(TURBOLINKS_AJAX_CACHE, 'app/javascript/packs/cloudflare_turbolinks_ajax_cache.js')
    return if File.read(packer_js).include?('cloudflare_turbolinks_ajax_cache')

    File.open(packer_js, 'a') { |f| f.puts "\nimport './cloudflare_turbolinks_ajax_cache'\n" }
  end
end
