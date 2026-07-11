require 'rails/generators'

module DeviseCloudflareTurnstile
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    desc 'Creates a Cloudflare Turnstile initializer and injects helpers into your layout'

    def check_dependencies
      return if File.exist?(File.join(destination_root, 'config/initializers/devise.rb'))

      say_status :error, 'Devise not installed. Run: rails generate devise:install', :red
      raise SystemExit
    end

    def create_initializer
      template 'cloudflare_turnstile.rb', 'config/initializers/cloudflare_turnstile.rb'
    end

    def inject_into_layout
      layout_file = 'app/views/layouts/application.html.erb'
      layout_path = File.join(destination_root, layout_file)

      unless File.exist?(layout_path)
        say_status :skip, "#{layout_file} not found — add helpers manually (see README)", :yellow
        return
      end

      if File.read(layout_path).include?('devise_turnstile_meta_tag')
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
  end
end
