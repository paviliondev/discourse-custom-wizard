# name: discourse-custom-wizard
# about: Allows the admins to create custom user input forms
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/custom_wizard.scss'

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
    get ':wizard_id' => 'wizard#index'
    get ':wizard_id/steps' => 'steps#index'
    get ':wizard_id/steps/:step_id' => 'wizard#index'
    put ':wizard_id/steps/:step_id' => 'steps#update'
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
      get 'admin/wizards/custom/:wizard_id' => 'admin#find'
      put 'admin/wizards/custom/save' => 'admin#save'
      delete 'admin/wizards/custom/remove' => 'admin#remove'
    end
  end

  class ::Wizard
    attr_accessor :id
  end

  class ::Wizard::Step
    attr_accessor :title
  end

  ::Wizard::Field.class_eval do
    attr_reader :label, :description

    def initialize(attrs)
      attrs = attrs || {}

      @id = attrs[:id]
      @type = attrs[:type]
      @required = !!attrs[:required]
      @label = attrs[:label]
      @description = attrs[:description]
      @value = attrs[:value]
      @choices = []
    end
  end

  add_to_serializer(:wizard, :id) { object.id }

  ::WizardStepSerializer.class_eval do
    def title
      if object.title
        object.title
      else
        I18n.t("#{i18n_key}.title", default: '')
      end
    end
  end

  ::WizardFieldSerializer.class_eval do
    def label
      puts "LABEL: #{object.label}"
      if object.label
        object.label
      else
        I18n.t("#{i18n_key}.label", default: '')
      end
    end

    def description
      if object.description
        object.description
      else
        I18n.t("#{i18n_key}.description", default: '')
      end
    end
  end
end
