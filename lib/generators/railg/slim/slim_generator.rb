module Railg
  class SlimGenerator < ::Rails::Generators::Base
    def add_gem
      gem 'slim-rails'
      gem 'html2slim', group: :development
    end

    def after_bundle_callback
      run 'erb2slim -d app/views/layouts/application.html.erb'
    end
  end
end
