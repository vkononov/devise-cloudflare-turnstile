# 1) allow `copy_file`/`directory` to find files in templates/shared
shared = File.expand_path('shared', __dir__)
source_paths.unshift(shared)

gem_root = File.expand_path('..', __dir__)
devise_version = ENV.fetch('DEVISE_VERSION')
invitable_version = ENV.fetch('DEVISE_INVITABLE_VERSION')

# 2) inject gems under test into the Gemfile
append_to_file 'Gemfile', <<~RUBY

  gem 'appraisal', require: false
  gem 'minitest-retry', require: false
  gem 'rails-controller-testing'

  if RUBY_VERSION >= '3.0.0'
    gem 'mutex_m'
    gem 'bigdecimal'
    gem 'drb'
    gem 'benchmark'
  end

  # i18n 1.15.0 uses the Fiber[] storage API (Ruby 3.2+) but declares support for
  # Ruby >= 3.1, so it installs and crashes on Ruby 3.1. Avoid it below 3.2.
  gem 'i18n', '!= 1.15.0' if RUBY_VERSION < '3.2.0'

  # Resolve the "uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger"
  gem 'concurrent-ruby', '< 1.3.5'

  # Rails currently has an incompatibility with minitest v6
  gem 'minitest', '< 6.0.0'

  #{if Rails::VERSION::STRING < '7.2.0'
      "gem 'rack', '< 3.0.0'"
    end}

  # Avoid Psych 4+ BadAlias with older Rails, and Psych 5 + stdlib Parser
  # mismatches that break sqlite3's mini_portile extconf on Ruby <= 3.0.
  #{unless Rails::VERSION::MAJOR >= 8
      "gem 'psych', '< 4'"
    end}

  gem 'devise', '= #{devise_version}'
  gem 'devise_invitable', '= #{invitable_version}'
  gem 'devise-cloudflare-turnstile', path: #{gem_root.inspect}
RUBY

# Pin sqlite3 by replacing the generator line — appending a second
# `gem 'sqlite3'` declaration makes Bundler reject the Gemfile.
# Rails 5.0 activates sqlite3 ~> 1.3.6; a 1.4.x install then fails at boot.
# Rails 6/7 default Gemfiles can resolve to 1.7+/2.x packaged builds that fail
# under older Rubies; 1.4.x uses system libsqlite3 instead.
if Rails::VERSION::STRING.start_with?('5.0')
  gsub_file 'Gemfile', /^\s*gem ['"]sqlite3['"].*$/, "gem 'sqlite3', '~> 1.3.6'"
elsif Rails::VERSION::STRING.start_with?('5.')
  gsub_file 'Gemfile', /^\s*gem ['"]sqlite3['"].*$/, "gem 'sqlite3', '~> 1.3', '< 1.5'"
elsif Rails::VERSION::MAJOR < 8
  gsub_file 'Gemfile', /^\s*gem ['"]sqlite3['"].*$/, "gem 'sqlite3', '~> 1.4.0'"
end

# 3) copy shared app files
%w[
  app/controllers/pages_controller.rb
  app/models/user.rb
  app/views/layouts/application.html.erb
  app/views/pages/home.html.erb
  app/views/pages/dual_forms.html.erb
  app/views/pages/widget_custom.html.erb
  config/initializers/cloudflare_turnstile.rb
  config/initializers/devise.rb.tt
  config/initializers/content_security_policy.rb.tt
  config/routes.rb
  db/migrate/20200101000000_devise_create_users.rb.tt
  test/application_system_test_case.rb
  test/support/turnstile_system_helpers.rb
  test/support/devise_system_helpers.rb
  test/controllers/sessions_controller_test.rb
  test/controllers/registrations_controller_test.rb
  test/controllers/passwords_controller_test.rb
  test/controllers/confirmations_controller_test.rb
  test/controllers/unlocks_controller_test.rb
  test/controllers/invitations_controller_test.rb
  test/controllers/pages_controller_test.rb
  test/system/sessions_test.rb
  test/system/registrations_test.rb
  test/system/passwords_test.rb
  test/system/confirmations_test.rb
  test/system/unlocks_test.rb
  test/system/invitations_test.rb
  test/system/turnstile_edge_cases_test.rb
  test/system/injector_behaviors_test.rb
  test/system/widget_customization_test.rb
].each do |shared_path|
  if shared_path.end_with?('.tt')
    template shared_path, shared_path.sub(/\.tt$/, ''), force: true
  else
    copy_file shared_path, shared_path, force: true
  end
end

# 4) configure minitest-retry and load support helpers in test_helper.rb
gsub_file 'test/test_helper.rb', %r{require ['"]rails/test_help['"]\n}, <<~RUBY
  require 'rails/test_help'
  require 'minitest/retry'

  Minitest::Retry.use! if ENV['CI'].present?

  Dir[Rails.root.join('test/support/**/*.rb')].sort.each { |f| require f }
RUBY

# 5) Turbolinks AJAX-cache helper (Rails 6 / Webpacker) — only when packs exist
packer_js = 'app/javascript/packs/application.js'
if File.exist?(packer_js)
  copy_file 'cloudflare_turbolinks_ajax_cache.js', 'app/javascript/packs/cloudflare_turbolinks_ajax_cache.js',
            force: true
  append_to_file packer_js, "\nimport './cloudflare_turbolinks_ajax_cache'\n"
end

# Rails 6 without Webpacker: Turbolinks + UJS via Sprockets so AJAX-cache
# behavior matches the foundational gem's Rails 6 coverage.
if Rails::VERSION::MAJOR == 6 && !File.exist?(packer_js)
  append_to_file 'Gemfile', <<~RUBY

    gem 'turbolinks', '~> 5'
  RUBY

  create_file 'app/assets/javascripts/application.js', <<~JS, force: true
    //= require rails-ujs
    //= require turbolinks
    //= require_tree .
  JS

  copy_file 'cloudflare_turbolinks_ajax_cache.js', 'app/assets/javascripts/cloudflare_turbolinks_ajax_cache.js',
            force: true
end

# 6) Remove chromedriver-helper / stock webdrivers (path bugs with modern
# selenium-webdriver). Re-add webdrivers for Rails 5.2 system tests.
gsub_file 'Gemfile', /^\s*gem ['"]chromedriver-helper['"].*\n/, ''
gsub_file 'Gemfile', /^\s*gem ['"]webdrivers['"].*\n/, ''
append_to_file 'Gemfile', "\ngem 'webdrivers'\n" if Rails::VERSION::STRING.start_with?('5.2.')

# 7) Ensure Devise and Invitable are required at boot (Zeitwerk / Rails 8)
inject_into_file 'config/application.rb', after: /Bundler\.require\(:?\*?Rails\.groups\)\n/ do
  <<~RUBY

    require 'devise'
    require 'devise_invitable'
  RUBY
end

# Rails 8 may leave Action Mailer commented out when Active Job is skipped;
# Devise mailers (confirmable/lockable/invitable/recoverable) need it.
gsub_file 'config/application.rb',
          '# require "action_mailer/railtie"',
          'require "action_mailer/railtie"'

# 8) Ensure Action Mailer uses :test in the test environment
environment 'config.action_mailer.delivery_method = :test', env: 'test'
environment 'config.action_mailer.default_url_options = { host: "www.example.com" }', env: 'test'

# System tests hit the real Cloudflare dummy widget; avoid parallel workers
# fighting over the same browser session / port.
environment 'config.active_support.test_parallelization_threshold = 1000', env: 'test' if Rails::VERSION::MAJOR >= 6
