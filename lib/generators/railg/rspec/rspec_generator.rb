module Railg
  class RspecGenerator < ::Rails::Generators::Base
    def gem_add
      gem 'rspec-rails', group: %i[development test]
    end

    def exec_bundle
      run 'bundle'
    end

    def after_bundle_do
      generate('rspec:install')
    end
  end
end
