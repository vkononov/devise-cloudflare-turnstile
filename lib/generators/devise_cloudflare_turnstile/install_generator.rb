require 'rails/generators'

module DeviseCloudflareTurnstile
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    desc 'Creates the Cloudflare Turnstile initializer'

    def check_dependencies
      return if File.exist?(File.join(destination_root, 'config/initializers/devise.rb'))

      say_status :error, 'Devise not installed. Run: rails generate devise:install', :red
      raise SystemExit
    end

    def create_initializer
      template 'cloudflare_turnstile.rb', 'config/initializers/cloudflare_turnstile.rb'
    end

    def show_layout_instructions
      say "\nAdd these helpers to your layout's <head> (e.g. app/views/layouts/application.html.erb):", :green
      say <<~ERB

        <%= devise_turnstile_meta_tag %>
        <%= devise_turnstile_scripts %>
      ERB
    end
  end
end
