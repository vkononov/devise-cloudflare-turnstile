$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

ENV['RAILS_ENV'] ||= 'test'

require 'logger'
require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_model'
require 'rails/generators'

require 'devise'
require 'cloudflare/turnstile/rails'
require 'devise/cloudflare/turnstile'

require 'minitest/autorun'
require 'minitest/mock'

module Dummy
  class Application < Rails::Application
    config.eager_load = false
    config.secret_key_base = 'devise-cloudflare-turnstile-test-secret'
    config.logger = Logger.new(File::NULL)
    config.hosts.clear if config.respond_to?(:hosts)

    # Rails 5.1+ Static middleware is keyword-only; MiddlewareStack forwards
    # options via *args, which breaks under Ruby 3. We do not need public
    # file serving in these tests.
    config.public_file_server.enabled = false if config.respond_to?(:public_file_server)

    # Rails 7.1+ uses a symbol; older versions expect a boolean.
    config.action_dispatch.show_exceptions = if Rails::VERSION::STRING >= '7.1'
                                               :none
                                             else
                                               false
                                             end

    if config.respond_to?(:content_security_policy)
      config.content_security_policy_nonce_generator = ->(_request) { 'test-nonce' }
      config.content_security_policy_nonce_directives = %w[script-src]
      config.content_security_policy do |policy|
        policy.script_src :self
      end
    end
  end
end

Rails.application.initialize!

# Rails 5.2 encrypted cookies are broken under Ruby 3: they pass positional
# Hashes into keyword-only MessageEncryptor / Metadata APIs. Patch those
# call sites so flash.now from Turnstile failures can commit a session.
if RUBY_VERSION >= '3' && Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR >= 2
  ActiveSupport::Messages::Metadata.singleton_class.class_eval do
    alias_method :wrap_without_ruby3_hash, :wrap

    def wrap(message, *args, **kwargs)
      kwargs = args.first.merge(kwargs) if args.first.is_a?(Hash)
      wrap_without_ruby3_hash(message, **kwargs)
    end
  end

  ActiveSupport::MessageEncryptor.class_eval do
    alias_method :encrypt_and_sign_without_ruby3_hash, :encrypt_and_sign

    def encrypt_and_sign(value, *args, **kwargs)
      kwargs = args.first.merge(kwargs) if args.first.is_a?(Hash)
      encrypt_and_sign_without_ruby3_hash(value, **kwargs)
    end
  end

  ActiveSupport::MessageVerifier.class_eval do
    alias_method :generate_without_ruby3_hash, :generate

    def generate(value, *args, **kwargs)
      kwargs = args.first.merge(kwargs) if args.first.is_a?(Hash)
      generate_without_ruby3_hash(value, **kwargs)
    end
  end
end

# On Rails 5.x the Runner's get/post helpers collect their arguments with *args
# and forward them to the session, so the request options (e.g. params:) arrive
# as a trailing positional Hash rather than keywords. Under Ruby 3's keyword
# separation that Hash can no longer flow into keyword-only `process` (6.0+
# marks the delegation with ruby2_keywords, so only Rails 5 needs this). Accept
# the options either positionally or as keywords and forward them as keywords.
if Rails::VERSION::MAJOR == 5
  module ActionDispatch
    module Integration
      module RequestHelpers
        %i[get post patch put head delete].each do |http_method|
          define_method(http_method) do |path, *args, **kwargs|
            options = args.first || kwargs
            process(http_method, path, **options)
          end
        end
      end
    end
  end
end

Cloudflare::Turnstile::Rails.configure do |config|
  config.site_key = 'SITEKEY'
  config.secret_key = 'SECRETKEY'
end

class DummyResource
  include ActiveModel::Model

  attr_accessor :email, :name, :password, :password_confirmation, :current_password

  class << self
    attr_accessor :clean_up_calls
  end

  def clean_up_passwords
    self.class.clean_up_calls = (self.class.clean_up_calls || 0) + 1
  end
end

class ViewHelperTestController < ActionController::Base
  TEMPLATE = '<%= devise_turnstile_meta_tag %>|<%= devise_turnstile_scripts %>'.freeze

  def protected_action
    @_devise_turnstile_protected = true
    render inline: TEMPLATE
  end

  def unprotected_action
    render inline: TEMPLATE
  end
end

class ConcernTestController < ActionController::Base
  include Devise::Cloudflare::Turnstile::ControllerConcern

  append_view_path File.expand_path('fixtures/views', __dir__)

  attr_accessor :resource, :minimum_password_length_set

  def resource_class
    DummyResource
  end

  def resource_name
    :dummy_resource
  end

  def clean_up_passwords(resource)
    resource.clean_up_passwords if resource.respond_to?(:clean_up_passwords)
  end

  def set_minimum_password_length
    @minimum_password_length_set = true
  end

  # Explicit render avoids Rails 5.0 + Ruby 3 breaking implicit template
  # lookup (ViewPaths#template_exists? is delegated without ruby2_keywords).
  def new
    render template: 'concern_test/new'
  end

  def edit
    render template: 'concern_test/edit'
  end

  def create
    render inline: ViewHelperTestController::TEMPLATE
  end

  # Exercise the update failure branch (verify is normally only on create).
  def update
    verify_cloudflare_turnstile!
    return if performed?

    render template: 'concern_test/edit'
  end
end

class SkipAllController < ActionController::Base
  include Devise::Cloudflare::Turnstile::ControllerConcern

  skip_turnstile

  attr_accessor :resource

  def resource_class
    DummyResource
  end

  def new
    render inline: ViewHelperTestController::TEMPLATE
  end

  def create
    render inline: ViewHelperTestController::TEMPLATE
  end
end

class SkipOnlyCreateController < ActionController::Base
  include Devise::Cloudflare::Turnstile::ControllerConcern

  skip_turnstile only: :create

  attr_accessor :resource

  def resource_class
    DummyResource
  end

  def new
    render inline: ViewHelperTestController::TEMPLATE
  end

  def create
    render inline: ViewHelperTestController::TEMPLATE
  end
end

class SkipExceptCreateController < ActionController::Base
  include Devise::Cloudflare::Turnstile::ControllerConcern

  skip_turnstile except: :create

  attr_accessor :resource

  def resource_class
    DummyResource
  end

  def new
    render inline: ViewHelperTestController::TEMPLATE
  end

  def create
    render inline: ViewHelperTestController::TEMPLATE
  end
end

class VerifyOptionsController < ActionController::Base
  include Devise::Cloudflare::Turnstile::ControllerConcern

  attr_accessor :resource

  def resource_class
    DummyResource
  end

  def create
    render inline: ViewHelperTestController::TEMPLATE
  end

  private

  def turnstile_verify_options
    { remoteip: '9.9.9.9' }
  end
end

Rails.application.routes.draw do
  get '/protected', to: 'view_helper_test#protected_action'
  get '/unprotected', to: 'view_helper_test#unprotected_action'
  get '/concern/new', to: 'concern_test#new'
  get '/concern/edit', to: 'concern_test#edit'
  post '/concern', to: 'concern_test#create'
  patch '/concern', to: 'concern_test#update'
  get '/skip_all/new', to: 'skip_all#new'
  post '/skip_all', to: 'skip_all#create'
  get '/skip_only/new', to: 'skip_only_create#new'
  post '/skip_only', to: 'skip_only_create#create'
  get '/skip_except/new', to: 'skip_except_create#new'
  post '/skip_except', to: 'skip_except_create#create'
  post '/verify_options', to: 'verify_options#create'
end

module TurnstileRequestHelpers
  def stub_verification(success:, &block)
    response = Cloudflare::Turnstile::Rails::VerificationResponse.new(
      'success' => success,
      'error-codes' => []
    )
    Cloudflare::Turnstile::Rails::Verification.stub(:verify, response, &block)
  end

  def with_secret(secret)
    original = Cloudflare::Turnstile::Rails.configuration.secret_key
    Cloudflare::Turnstile::Rails.configuration.secret_key = secret
    yield
  ensure
    Cloudflare::Turnstile::Rails.configuration.secret_key = original
  end

  def with_site_key(site_key)
    original = Cloudflare::Turnstile::Rails.configuration.site_key
    Cloudflare::Turnstile::Rails.configuration.site_key = site_key
    yield
  ensure
    Cloudflare::Turnstile::Rails.configuration.site_key = original
  end

  def with_devise_skip(*controllers, **actions)
    Cloudflare::Turnstile::Rails.configuration.skip(*controllers, **actions)
    yield
  ensure
    Cloudflare::Turnstile::Rails.configuration.skips.clear
  end

  def with_default_data(data)
    original = Cloudflare::Turnstile::Rails.configuration.default_data
    Cloudflare::Turnstile::Rails.configuration.default_data = data
    yield
  ensure
    Cloudflare::Turnstile::Rails.configuration.default_data = original
  end

  def capture_turnstile_verify_args(&block)
    captured = {}
    fake = lambda do |**kwargs|
      captured = kwargs
      Cloudflare::Turnstile::Rails::VerificationResponse.new('success' => true, 'error-codes' => [])
    end
    Cloudflare::Turnstile::Rails::Verification.stub(:verify, fake, &block)
    captured
  end
end
