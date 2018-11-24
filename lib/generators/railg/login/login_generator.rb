module Railg
  class LoginGenerator < ::Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    argument :id_name, type: :string, default: 'identifier', banner: 'column name like email'

    check_class_collision

    def gem_bcrypt
      gem 'bcrypt'
    end

    def insert_header
      insert_into_file 'app/views/layouts/application.html.erb', <<-TAG, after: "  <body>\n"
    <%= render 'header' %>
      TAG
    end

    def add_route
      route 'resource  :session, only: %i[new create destroy]'
      route "resources :#{plural_route_name}, only: %i[new create]"
    end

    def create_account_model
      create_file "app/models/#{file_path}.rb", <<-EOT
# frozen_string_literal: true

class #{class_name} < ApplicationRecord
  has_secure_password

  validates :#{id_name}, presence: true, uniqueness: true
end
      EOT

      create_file "db/migrate/20181105044958_create_#{plural_table_name}.rb", <<-EOT
class Create#{plural_table_name.capitalize} < ActiveRecord::Migration[5.2]
  def change
    create_table :#{plural_table_name} do |t|
      t.string :#{id_name}, null: false
      t.string :password_digest, null: false
      t.index :#{id_name}, unique: true

      t.timestamps
    end
  end
end
EOT
    end

    def create_view_files
      create_file 'app/views/application/_header.html.slim', <<-EOT
nav.navbar
  .container
    .navbar-menu
      .navbar-end
        .navbar-item
          = form_with url: session_url, method: :delete do |f|
            .buttons
              - unless signed_in?
                = link_to 'sign in', new_session_path, class: 'button is-text'
                = link_to 'sign up', #{new_helper}, class: 'button is-text'
              - else
                = f.submit 'sign out', class: 'button is-text'
      EOT

      create_file "app/views/#{plural_file_name}/new.html.slim", <<-EOT
section.section
  .container
    = form_with model: #{redirect_resource_name} do |f|
      .field
        .control
          = f.text_field :#{id_name}, class: 'input'
      .field
        .control
          = f.password_field :password, class: 'input'
      .field
        .control
          = f.password_field :password_confirmation, class: 'input'
      .field
        .control
          = f.submit class: 'button'
      EOT

      create_file 'app/views/sessions/new.html.slim', <<-EOT
section.section
  .container
    = form_with url: session_url do |f|
      .field
        .control
          = f.text_field :#{id_name}, class: 'input'
      .field
        .control
          = f.password_field :password, class: 'input'
      .field
        .control
          label.checkbox
            = f.check_box :remember, {}, true, false
            | Remember me?
      .field
        .control
          = f.submit class: 'button'
      EOT
    end

    def create_controller_files
      create_file "app/controllers/#{plural_name}_controller.rb", <<-EOT
# frozen_string_literal: true

class #{plural_name.capitalize}Controller < ApplicationController
  def new
    #{redirect_resource_name} = #{class_name}.new
  end

  def create
    #{redirect_resource_name} = #{class_name}.new(#{singular_name}_params)

    if #{redirect_resource_name}.save
      redirect_to new_session_path
    else
      render :new
    end
  end

  private

  def #{singular_name}_params
    params.require(:#{singular_name}).permit(:#{id_name}, :password, :password_confirmation)
  end
end
      EOT

      create_file 'app/controllers/auth_controller.rb', <<-EOT
# frozen_string_literal: true

class AuthController < ApplicationController
  rescue_from 'SessionManager::NoSigninError', with: -> { redirect_to new_session_path }

  before_action :current_#{singular_name} # require signin by raising SessionManager::NoSigninError
end
      EOT

      create_file 'app/controllers/sessions_controller.rb', <<-EOT
# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
  end

  def create
    #{singular_name} = #{class_name}.find_by(#{id_name}: params[:#{id_name}])

    if #{singular_name} && #{singular_name}.authenticate(params[:password])
      retain_session(#{singular_name}, remember: params[:remember])
      redirect_to root_path
    else
      render :new
    end
  end

  def destroy
    free_session
  end
end
      EOT

      create_file 'app/controllers/session_manager.rb', <<-EOT
# frozen_string_literal: true

module SessionManager
  extend ActiveSupport::Concern

  SESSION_KEY = :#{singular_name}_id
  NoSigninError = Class.new(StandardError)

  included do
    helper_method :signed_in?
  end

  private

  def retain_session(#{singular_name}, remember: false)
    session[SESSION_KEY] = #{singular_name}.id

    if remember
      # TODO: impl
    end
  end

  def free_session
    session[SESSION_KEY] = nil
  end

  # TODO: refact
  def current_#{singular_name}
    if (id = session[SESSION_KEY])
      #{class_name}.find(id)
    elsif (id = cookies.signed[SESSION_KEY])
      #{singular_name} = #{class_name}.find(id)
      raise NoSigninError unless #{singular_name}.authenticated?(cookies[:remember_token])

      sign_in(#{singular_name}) # sessionにも保存
      #{singular_name}
    else
      raise NoSigninError
    end
  end

  def signed_in?
    current_#{singular_name}
    true
  rescue NoSigninError
    false
  end
end
      EOT

      insert_into_file 'app/controllers/application_controller.rb', <<-EOT, after: "class ApplicationController < ActionController::Base\n"
  include SessionManager
      EOT
    end

    def insert_header
      insert_into_file 'app/views/layouts/application.html.erb', <<-EOT, after: "  <body>\n"
    <%= render 'header' %>
      EOT
    end

    def after_bundle_callback
      rake 'db:migrate'
    end
  end
end
