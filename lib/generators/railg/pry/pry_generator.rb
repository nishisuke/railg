module Railg
  class PryGenerator < ::Rails::Generators::Base
    def add_gem
      gem 'pry-rails', group: :development
      gem 'pry-byebug', group: :development
    end
  end
end
