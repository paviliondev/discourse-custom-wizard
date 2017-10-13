# name: discourse-custom-wizard
# about: Create custom wizards
# version: 0.1
# authors: Angus McLeod

register_asset 'stylesheets/wizard_custom_admin.scss'

config = Rails.application.config
config.assets.paths << Rails.root.join("plugins", "discourse-custom-wizard", "assets", "javascripts")
config.assets.paths << Rails.root.join("plugins", "discourse-custom-wizard", "assets", "stylesheets", "wizard")

after_initialize do
  require_dependency "application_controller"
  module ::CustomWizard
    class Engine < ::Rails::Engine
      engine_name "custom_wizard"
      isolate_namespace CustomWizard
    end
  end

  load File.expand_path('../lib/builder.rb', __FILE__)
  load File.expand_path('../lib/field.rb', __FILE__)
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
      get 'admin/wizards/submissions/all' => 'admin#submissions'
      get 'admin/wizards/submissions/:wizard_id' => 'admin#find_submissions'
    end
  end

  require_dependency 'wizard'
  require_dependency 'wizard/step'
  require_dependency 'wizard/step_updater'
  require_dependency 'wizard/field'

  ::Wizard.class_eval do
    attr_accessor :id, :background, :save_submissions, :multiple_submissions

    def initialize(user, attrs = {})
      @steps = []
      @user = user
      @first_step = nil
      @max_topics_to_require_completion = 15
      @id = attrs[:id] if attrs[:id]
      @save_submissions = attrs[:save_submissions] if attrs[:save_submissions]
      @multiple_submissions = attrs[:multiple_submissions] if attrs[:multiple_submissions]
      @background = attrs[:background] if attrs[:background]
      @custom = attrs[:custom] if attrs[:custom]
    end

    def completed?
      completed_steps?(@steps.map(&:id))
    end

    def completed_steps?(steps)
      steps = [steps].flatten.uniq

      completed = UserHistory.where(
        acting_user_id: @user.id,
        action: UserHistory.actions[:wizard_step]
      ).where(context: steps)
        .distinct.order(:context).pluck(:context)

      steps.sort == completed
    end

    def start
      completed = UserHistory.where(
        acting_user_id: @user.id,
        action: UserHistory.actions[:wizard_step]
      ).where(context: @steps.map(&:id))
        .uniq.pluck(:context)

      # First uncompleted step
      steps = @custom ? @steps : steps_with_fields
      steps.each do |s|
        return s unless completed.include?(s.id)
      end

      @first_step
    end
  end

  ::Wizard::Field.class_eval do
    attr_reader :label, :description, :key, :min_length

    def initialize(attrs)
      attrs = attrs || {}

      @id = attrs[:id]
      @type = attrs[:type]
      @required = !!attrs[:required]
      @label = attrs[:label]
      @description = attrs[:description]
      @key = attrs[:key]
      @min_length = attrs[:min_length]
      @value = attrs[:value]
      @choices = []
    end
  end

  class ::Wizard::Step
    attr_accessor :title, :description, :key
  end

  class ::Wizard::StepUpdater
    attr_accessor :result, :step
  end

  ::WizardSerializer.class_eval do
    attributes :id, :background, :completed

    def id
      object.id
    end

    def background
      object.background
    end

    def completed
      object.completed?
    end

    def include_completed?
      object.completed? && !object.multiple_submissions && !scope.current_user.admin?
    end

    def include_start?
      object.start && include_steps?
    end

    def include_steps?
      !include_completed?
    end
  end

  ::WizardStepSerializer.class_eval do
    def title
      return object.title if object.title
      I18n.t("#{object.key || i18n_key}.title", default: '')
    end

    def description
      return object.description if object.description
      I18n.t("#{object.key || i18n_key}.description", default: '')
    end
  end

  ::WizardFieldSerializer.class_eval do
    def label
      return object.label if object.label
      I18n.t("#{object.key || i18n_key}.label", default: '')
    end

    def description
      return object.description if object.description
      I18n.t("#{object.key || i18n_key}.description", default: '')
    end

    def placeholder
      I18n.t("#{object.key || i18n_key}.placeholder", default: '')
    end
  end
end
