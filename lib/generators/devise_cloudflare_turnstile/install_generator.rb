require 'rails/generators'

module DeviseCloudflareTurnstile
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    desc 'Creates a Cloudflare Turnstile initializer and injects helpers into your layout'

    def check_dependencies
      return if File.exist?('config/initializers/devise.rb')

      say_status :error, 'Devise not installed. Run: rails generate devise:install', :red
      raise SystemExit
    end

    def create_initializer
      template 'cloudflare_turnstile.rb', 'config/initializers/cloudflare_turnstile.rb'
    end

    def inject_into_layout
      layout_file = 'app/views/layouts/application.html.erb'

      unless File.exist?(layout_file)
        say_status :skip, "#{layout_file} not found - add helpers manually (see instructions below)", :yellow
        return
      end

      if File.read(layout_file).include?('cf-turnstile-site-key')
        say_status :skip, "#{layout_file} already configured", :yellow
        return
      end

      inject_into_file layout_file, after: /<head>.*\n/i do
        <<-ERB
    <%= devise_turnstile_meta_tag %>
    <%= devise_turnstile_scripts %>
        ERB
      end
      say_status :inject, layout_file, :green
    end

    def print_instructions
      say ''
      say '=' * 60
      say 'Devise Cloudflare Turnstile installed!'
      say '=' * 60
      say ''
      say 'Next steps:'
      say ''
      say '1. Set your Cloudflare Turnstile credentials:'
      say ''
      say '   Option A: Environment variables (recommended)'
      say '     export CLOUDFLARE_TURNSTILE_SITE_KEY=your_site_key'
      say '     export CLOUDFLARE_TURNSTILE_SECRET_KEY=your_secret_key'
      say ''
      say '   Option B: Edit config/initializers/cloudflare_turnstile.rb'
      say ''
      say '2. Get your keys from:'
      say '   https://dash.cloudflare.com/turnstile'
      say ''
      say 'For testing/development, use these dummy keys:'
      say '  Site Key:   1x00000000000000000000AA (always passes)'
      say '  Secret Key: 1x0000000000000000000000000000000AA (always passes)'
      say ''
      say '-' * 60
      say ''
      say 'If the layout injection was skipped, add these lines to your'
      say "layout's <head> section:"
      say ''
      say '  <%= devise_turnstile_meta_tag %>'
      say '  <%= devise_turnstile_scripts %>'
      say ''
    end
  end
end
