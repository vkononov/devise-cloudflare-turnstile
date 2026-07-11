$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

ENV['RAILS_ENV'] ||= 'test'

require 'logger'
require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_model'

require 'devise'
require 'cloudflare/turnstile/rails'
require 'devise/cloudflare/turnstile'

require 'minitest/autorun'

module Dummy
  class Application < Rails::Application
    config.eager_load = false
    config.secret_key_base = 'devise-cloudflare-turnstile-test-secret'
    config.logger = Logger.new(File::NULL)
    config.hosts.clear if config.respond_to?(:hosts)

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

Cloudflare::Turnstile::Rails.configure do |config|
  config.site_key = '1x00000000000000000000AA'
  config.secret_key = '1x0000000000000000000000000000000AA'
end

class DummyResource
  include ActiveModel::Model

  def clean_up_passwords; end
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

  attr_accessor :resource

  def resource_class
    DummyResource
  end

  def clean_up_passwords(resource)
    resource.clean_up_passwords if resource.respond_to?(:clean_up_passwords)
  end

  def new
    render plain: "new:#{@_devise_turnstile_protected.inspect}"
  end

  def edit
    render plain: "edit:#{@_devise_turnstile_protected.inspect}"
  end

  def create
    render inline: ViewHelperTestController::TEMPLATE
  end
end

Rails.application.routes.draw do
  get '/protected', to: 'view_helper_test#protected_action'
  get '/unprotected', to: 'view_helper_test#unprotected_action'
  get '/concern/new', to: 'concern_test#new'
  get '/concern/edit', to: 'concern_test#edit'
  post '/concern', to: 'concern_test#create'
end

module TurnstileConfig
  def with_secret(secret)
    original = Cloudflare::Turnstile::Rails.configuration.secret_key
    Cloudflare::Turnstile::Rails.configuration.secret_key = secret
    yield
  ensure
    Cloudflare::Turnstile::Rails.configuration.secret_key = original
  end
end
