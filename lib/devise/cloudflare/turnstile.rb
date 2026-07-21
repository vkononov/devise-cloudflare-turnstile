require 'devise'
require 'cloudflare/turnstile/rails'

require_relative 'turnstile/version'
require_relative 'turnstile/configuration'
require_relative 'turnstile/controller_concern'
require_relative 'turnstile/view_helpers'
require_relative 'turnstile/engine'
require_relative 'turnstile/railtie'

module Devise
  module Cloudflare
    module Turnstile
      class Error < StandardError; end

      def self.configuration
        @configuration ||= Configuration.new
      end

      def self.configure
        yield configuration
      end
    end
  end
end
