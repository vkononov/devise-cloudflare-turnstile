# frozen_string_literal: true

require_relative "lib/devise/cloudflare/turnstile/version"

Gem::Specification.new do |spec|
  spec.name = "devise-cloudflare-turnstile"
  spec.version = Devise::Cloudflare::Turnstile::VERSION
  spec.authors = ["Vadim Kononov"]
  spec.email = ["vadim@poetic.com"]

  spec.summary = "Cloudflare Turnstile integration for Devise"
  spec.description = "Automatically protect all Devise authentication forms with Cloudflare Turnstile. " \
                     "Zero configuration required - just install and set your API keys."
  spec.homepage = "https://github.com/vkononov/devise-cloudflare-turnstile"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*",
    "app/**/*",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "devise", ">= 4.0"
  spec.add_dependency "cloudflare-turnstile-rails", ">= 1.0"
  spec.add_dependency "rails", ">= 6.0"
end
