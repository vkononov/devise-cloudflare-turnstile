require 'rails/generators'
require 'generators/cloudflare_turnstile/install_generator'

module DeviseCloudflareTurnstile
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    INITIALIZER = 'config/initializers/cloudflare_turnstile.rb'.freeze

    desc 'Creates the Cloudflare Turnstile initializer with Devise-specific options'

    def check_dependencies
      return if File.exist?(File.join(destination_root, 'config/initializers/devise.rb'))

      say_status :error, 'Devise not installed. Run: rails generate devise:install', :red
      raise SystemExit
    end

    def create_initializer
      create_file INITIALIZER, combined_initializer
    end

    def show_layout_instructions
      say "\nAdd these helpers to your layout's <head> (e.g. app/views/layouts/application.html.erb):", :green
      say <<~ERB

        <%= devise_turnstile_meta_tag %>
        <%= devise_turnstile_scripts %>
      ERB
    end

    private

    # Reuses cloudflare-turnstile-rails' initializer verbatim (single source of
    # truth) and injects our Devise-specific options into its config block,
    # indented to match. Add new options by editing templates/devise_options.rb.
    def combined_initializer
      foundational_initializer.sub(/\nend\s*\z/, "\n\n#{devise_options}end\n")
    end

    def foundational_initializer
      template = File.expand_path('cloudflare_turnstile.rb', CloudflareTurnstile::Generators::InstallGenerator.source_root)
      File.read(template)
    end

    def devise_options
      File.read(File.expand_path('devise_options.rb', self.class.source_root)).gsub(/^(?=.)/, '  ')
    end
  end
end
