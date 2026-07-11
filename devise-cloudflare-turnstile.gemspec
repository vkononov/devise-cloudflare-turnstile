require_relative 'lib/devise/cloudflare/turnstile/version'

Gem::Specification.new do |spec|
  spec.name = 'devise-cloudflare-turnstile'
  spec.version = Devise::Cloudflare::Turnstile::VERSION
  spec.authors = ['Vadim Kononov']
  spec.email = ['vadim@konoson.com']

  spec.summary = 'Cloudflare Turnstile integration for Devise'
  spec.description = 'Automatically protect all Devise authentication forms with Cloudflare Turnstile. ' \
                     'Zero configuration required — just install and set your API keys.'
  spec.homepage = 'https://github.com/vkononov/devise-cloudflare-turnstile'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Ship only what the gem needs at runtime: library code, assets, generators,
  # plus license and readme. Using an allowlist keeps tests, tooling, and CI
  # config out of the package.
  root_files = %w[LICENSE.txt README.md]
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).select do |f|
      f.start_with?('lib/', 'app/') || root_files.include?(f)
    end
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'cloudflare-turnstile-rails', '>= 1.0'
  spec.add_dependency 'devise', '>= 4.0'
end
