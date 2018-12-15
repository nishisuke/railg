module Railg
  class DefaultGenerator < ::Rails::Generators::Base
    def configure_generator
      environment <<-EOT, env: 'development'
  config.generators do |g|
    g.orm :ar_null_false_generator
    g.assets false
    g.helper false
    g.jbuilder false
    g.test_framework false
  end
      EOT
    end

    def gem_add
      gem 'ar_null_false_generator', group: :development
    end

    def insert_meta_tag
      insert_into_file 'app/views/layouts/application.html.erb', <<-EOT, after: "  <head>\n"
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
      EOT
    end

    def create_db
      rake 'db:create'
    end
  end
end
