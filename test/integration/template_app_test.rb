require 'bundler'
require 'fileutils'

module TemplateAppTest
  TEMPLATE = File.expand_path('../../templates/template.rb', __dir__)

  def setup_template_app
    @tmpdir = Dir.mktmpdir('devise_cf_turnstile')
  end

  def teardown_template_app
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
end
