module Railg
  class FbotGenerator < ::Rails::Generators::Base
    def gem_add
      gem 'factory_bot_rails', group: %i[development test]
    end

    def exec_bundle
      run 'bundle'
    end

    def after_bundle_do
      create_file 'spec/support/factory_bot.rb', <<~CODE
        # frozen_string_literal: true
        RSpec.configure do |config|
          config.include FactoryBot::Syntax::Methods
        end
      CODE

      insert_into_file 'spec/rails_helper.rb', <<~EOT, after: "# Add additional requires below this line. Rails is not loaded until this point!\n"
        require_relative 'support/factory_bot.rb'
      EOT
    end
  end
end
