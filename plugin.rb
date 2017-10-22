# name: discourse-custom-wizard
# about: Create custom wizards
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/wizard_custom_admin.scss'

config = Rails.application.config
config.assets.paths << Rails.root.join('plugins', 'discourse-custom-wizard', 'assets', 'javascripts')
config.assets.paths << Rails.root.join('plugins', 'discourse-custom-wizard', 'assets', 'stylesheets', 'wizard')

after_initialize do
  UserHistory.actions[:custom_wizard_step] = 1000

  require_dependency 'application_controller'
  module ::CustomWizard
    class Engine < ::Rails::Engine
      engine_name 'custom_wizard'
      isolate_namespace CustomWizard
    end
  end

  CustomWizard::Engine.routes.draw do
    get ':wizard_id' => 'wizard#index'
    get ':wizard_id/steps' => 'wizard#index'
    get ':wizard_id/steps/:step_id' => 'wizard#index'
    put ':wizard_id/steps/:step_id' => 'steps#update'
  end

  require_dependency 'admin_constraint'
  Discourse::Application.routes.append do
    mount ::CustomWizard::Engine, at: 'w'

    scope module: 'custom_wizard', constraints: AdminConstraint.new do
      get 'admin/wizards' => 'admin#index'
      get 'admin/wizards/field-types' => 'admin#field_types'
      get 'admin/wizards/custom' => 'admin#index'
      get 'admin/wizards/custom/new' => 'admin#index'
      get 'admin/wizards/custom/all' => 'admin#custom_wizards'
      get 'admin/wizards/custom/:wizard_id' => 'admin#find_wizard'
      put 'admin/wizards/custom/save' => 'admin#save'
      delete 'admin/wizards/custom/remove' => 'admin#remove'
      get 'admin/wizards/submissions' => 'admin#index'
      get 'admin/wizards/submissions/:wizard_id' => 'admin#submissions'
    end
  end

  load File.expand_path('../lib/builder.rb', __FILE__)
  load File.expand_path('../lib/field.rb', __FILE__)
  load File.expand_path('../lib/step_updater.rb', __FILE__)
  load File.expand_path('../lib/template.rb', __FILE__)
  load File.expand_path('../lib/wizard.rb', __FILE__)
  load File.expand_path('../lib/wizard_edits.rb', __FILE__)
  load File.expand_path('../controllers/wizard.rb', __FILE__)
  load File.expand_path('../controllers/steps.rb', __FILE__)
  load File.expand_path('../controllers/admin.rb', __FILE__)
end
