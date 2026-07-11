require 'devise'
require 'cloudflare/turnstile/rails'

require_relative 'turnstile/version'
require_relative 'turnstile/controller_concern'
require_relative 'turnstile/view_helpers'
require_relative 'turnstile/engine'
require_relative 'turnstile/railtie'

module Devise
  module Cloudflare
    module Turnstile
      class Error < StandardError; end
    end
  end
end
