module Railg
  class LoginGenerator < ::Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def gem_bcrypt
      gem 'bcrypt'
    end

    def add_route
      route 'resource  :session, only: %i[new create destroy]'
      route 'resources :accounts, only: %i[new create]'
    end

    def create_account_model
      create_file 'app/models/account.rb', <<-EOT
# frozen_string_literal: true

class Account < ApplicationRecord
  has_secure_password

  validates :identifier, presence: true, uniqueness: true
end
      EOT

      create_file 'db/migrate/20181105044958_create_accounts.rb', <<-EOT
class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.string :identifier, null: false
      t.string :password_digest, null: false
      t.index :identifier, unique: true

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
                = link_to 'sign up', new_account_path, class: 'button is-text'
              - else
                = f.submit 'sign out', class: 'button is-text'
      EOT

      create_file 'app/views/accounts/new.html.slim', <<-EOT
section.section
  .container
    = form_with model: @account do |f|
      .field
        .control
          = f.text_field :identifier, class: 'input'
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
          = f.text_field :identifier, class: 'input'
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
      create_file 'app/controllers/accounts_controller.rb', <<-EOT
# frozen_string_literal: true

class AccountsController < ApplicationController
  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    if @account.save
      redirect_to new_session_path
    else
      render :new
    end
  end

  private

  def account_params
    params.require(:account).permit(:identifier, :password, :password_confirmation)
  end
end
      EOT

      create_file 'app/controllers/auth_controller.rb', <<-EOT
# frozen_string_literal: true

class AuthController < ApplicationController
  rescue_from 'SessionManager::NoSigninError', with: -> { redirect_to new_session_path }

  before_action :current_account # require signin by raising SessionManager::NoSigninError
end
      EOT

      create_file 'app/controllers/sessions_controller.rb', <<-EOT
# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
  end

  def create
    account = Account.find_by(identifier: params[:identifier])

    if account && account.authenticate(params[:password])
      retain_session(account, remember: params[:remember])
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

  SESSION_KEY = :account_id
  NoSigninError = Class.new(StandardError)

  included do
    helper_method :signed_in?
  end

  private

  def retain_session(account, remember: false)
    session[SESSION_KEY] = account.id

    if remember
      # TODO: impl
    end
  end

  def free_session
    session[SESSION_KEY] = nil
  end

  # TODO: refact
  def current_account
    if (id = session[SESSION_KEY])
      Account.find(id)
    elsif (id = cookies.signed[SESSION_KEY])
      account = Account.find(id)
      raise NoSigninError unless account.authenticated?(cookies[:remember_token])

      sign_in(account) # sessionにも保存
      account
    else
      raise NoSigninError
    end
  end

  def signed_in?
    current_account
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
