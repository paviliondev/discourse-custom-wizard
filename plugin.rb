# name: discourse-custom-wizard
# about: Allows the admins to create custom user input forms
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/custom-wizard.scss'

after_initialize do
  require_dependency "application_controller"
  module ::CustomWizard
    class Engine < ::Rails::Engine
      engine_name "custom_wizard"
      isolate_namespace CustomWizard
    end
  end

  CustomWizard::Engine.routes.draw do
    get 'custom' => 'admin#index'
    get 'custom/new' => 'admin#index'
    get 'custom/all' => "admin#all"
    get 'custom/:id' => "admin#find"
    put 'custom/save' => "admin#save"
    delete 'custom/remove' => "admin#remove"
  end

  require_dependency 'admin_constraint'
  Discourse::Application.routes.append do

    namespace :admin, constraints: AdminConstraint.new do
      mount ::CustomWizard::Engine, at: 'wizards'
    end
  end

  load File.expand_path('../lib/builder.rb', __FILE__)
  load File.expand_path('../lib/wizard.rb', __FILE__)
  load File.expand_path('../controllers/steps.rb', __FILE__)
  load File.expand_path('../controllers/admin.rb', __FILE__)
end
