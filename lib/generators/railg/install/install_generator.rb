module Railg
  class InstallGenerator < ::Rails::Generators::Base
    hook_for :default, type: :boolean, default: true
    hook_for :pry,     type: :boolean, default: true
    hook_for :bulma,   type: :boolean, default: false
    hook_for :rspec,   type: :boolean, default: false
    hook_for :fbot,    type: :boolean, default: false
    hook_for :login,   type: :boolean, default: false
    hook_for :slim,    type: :boolean, default: true # must be last
  end
end
