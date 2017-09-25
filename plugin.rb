# name: discourse-custom-wizard
# about: Allows the admins to create custom user input forms
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/custom-wizard.scss'

config = Rails.application.config
config.assets.paths << Rails.root.join("plugins", "discourse-custom-wizard", "assets", "javascripts")

after_initialize do
  require_dependency "application_controller"
  module ::CustomWizard
    class Engine < ::Rails::Engine
      engine_name "custom_wizard"
      isolate_namespace CustomWizard
    end
  end

  load File.expand_path('../lib/builder.rb', __FILE__)
  load File.expand_path('../lib/wizard.rb', __FILE__)
  load File.expand_path('../app/controllers/wizard.rb', __FILE__)
  load File.expand_path('../app/controllers/steps.rb', __FILE__)
  load File.expand_path('../app/controllers/admin.rb', __FILE__)

  CustomWizard::Engine.routes.draw do
    get ':name' => 'wizard#index'
    get ':name/steps' => 'steps#index'
    get ':name/steps/:id' => 'wizard#index'
    put ':name/steps/:id' => 'steps#update'
  end

  require_dependency 'admin_constraint'
  Discourse::Application.routes.append do
    namespace :wizard do
      mount ::CustomWizard::Engine, at: 'custom'
    end

    scope module: 'custom_wizard', constraints: AdminConstraint.new do
      get 'admin/wizards/custom' => 'admin#index'
      get 'admin/wizards/custom/new' => 'admin#index'
      get 'admin/wizards/custom/all' => 'admin#all'
      get 'admin/wizards/custom/:id' => 'admin#find'
      put 'admin/wizards/custom/save' => 'admin#save'
      delete 'admin/wizards/custom/remove' => 'admin#remove'
    end
  end
end
