# name: discourse-custom-wizard
# about: Create custom wizards
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-custom-wizard

register_asset 'stylesheets/wizard_custom_admin.scss'
register_asset 'lib/jquery.timepicker.min.js'
register_asset 'lib/jquery.timepicker.scss'

enabled_site_setting :custom_wizard_enabled

config = Rails.application.config
config.assets.paths << Rails.root.join('plugins', 'discourse-custom-wizard', 'assets', 'javascripts')
config.assets.paths << Rails.root.join('plugins', 'discourse-custom-wizard', 'assets', 'stylesheets', 'wizard')

if Rails.env.production?
  config.assets.precompile += %w{
    wizard-custom-guest.js
    wizard-custom-lib.js
    wizard-custom.js
    wizard-plugin.js
    wizard-custom-start.js
    wizard-raw-templates.js.erb
    stylesheets/wizard/wizard_custom.scss
    stylesheets/wizard/wizard_composer.scss
    stylesheets/wizard/wizard_variables.scss
    stylesheets/wizard/wizard_custom_mobile.scss
  }
end

if respond_to?(:register_svg_icon)
  register_svg_icon "calendar-o"
  register_svg_icon "chevron-right"
  register_svg_icon "chevron-left"
end

after_initialize do
  [
    '../lib/custom_wizard/engine.rb',
    '../config/routes.rb',
    '../controllers/custom_wizard/wizard.rb',
    '../controllers/custom_wizard/steps.rb',
    '../controllers/custom_wizard/admin.rb',
    '../controllers/custom_wizard/transfer.rb',
    '../controllers/custom_wizard/api.rb',
    '../jobs/clear_after_time_wizard.rb',
    '../jobs/refresh_api_access_token.rb',
    '../jobs/set_after_time_wizard.rb',
    '../lib/custom_wizard/builder.rb',
    '../lib/custom_wizard/field.rb',
    '../lib/custom_wizard/flags.rb',
    '../lib/custom_wizard/step_updater.rb',
    '../lib/custom_wizard/template.rb',
    '../lib/custom_wizard/wizard.rb',
    '../lib/custom_wizard/api/api.rb',
    '../lib/custom_wizard/api/authorization.rb',
    '../lib/custom_wizard/api/endpoint.rb',
    '../lib/custom_wizard/api/log_entry.rb',
    '../serializers/custom_wizard/api_serializer.rb',
    '../serializers/custom_wizard/basic_api_serializer.rb',
    '../serializers/custom_wizard/api/authorization_serializer.rb',
    '../serializers/custom_wizard/api/basic_endpoint_serializer.rb',
    '../serializers/custom_wizard/api/endpoint_serializer.rb',
    '../serializers/custom_wizard/api/log_serializer.rb'
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  ::Wizard.class_eval do
    def self.user_requires_completion?(user)
      wizard_result = self.new(user).requires_completion?
      return wizard_result if wizard_result

      custom_redirect = false

      if user && user.first_seen_at.blank? && wizard_id = CustomWizard::Wizard.after_signup
        wizard = CustomWizard::Wizard.create(user, wizard_id)

        if !wizard.completed? && wizard.permitted?
          custom_redirect = true
          CustomWizard::Wizard.set_wizard_redirect(user, wizard_id)
        end
      end

      !!custom_redirect
    end
  end

  ::Wizard::Field.class_eval do
    attr_reader :label, :description, :image, :key, :min_length, :file_types, :limit, :property
    attr_accessor :dropdown_none

    def initialize(attrs)
      @attrs = attrs || {}
      @id = attrs[:id]
      @type = attrs[:type]
      @required = !!attrs[:required]
      @description = attrs[:description]
      @image = attrs[:image]
      @key = attrs[:key]
      @min_length = attrs[:min_length]
      @value = attrs[:value]
      @choices = []
      @dropdown_none = attrs[:dropdown_none]
      @file_types = attrs[:file_types]
      @limit = attrs[:limit]
      @property = attrs[:property]
    end

    def label
      @label ||= PrettyText.cook(@attrs[:label])
    end
  end

  ::Wizard::Choice.class_eval do
    def initialize(id, opts)
      @id = id
      @opts = opts
      @data = opts[:data]
      @extra_label = opts[:extra_label]
      @icon = opts[:icon]
    end

    def label
      @label ||= PrettyText.cook(@opts[:label])
    end
  end

  class ::Wizard::Step
    attr_accessor :title, :description, :key, :permitted, :permitted_message
  end

  ::WizardSerializer.class_eval do
    attributes :id,
               :name,
               :background,
               :completed,
               :required,
               :min_trust,
               :permitted,
               :user,
               :categories,
               :uncategorized_category_id

    def id
      object.id
    end

    def include_id?
      object.respond_to?(:id)
    end

    def name
      object.name
    end
    
    def include_name?
      object.respond_to?(:name)
    end

    def background
      object.background
    end

    def include_background?
      object.respond_to?(:background)
    end

    def completed
      object.completed?
    end

    def include_completed?
      object.completed? &&
      (!object.respond_to?(:multiple_submissions) || !object.multiple_submissions) &&
      !scope.is_admin?
    end

    def min_trust
      object.min_trust
    end

    def include_min_trust?
      object.respond_to?(:min_trust)
    end

    def permitted
      object.permitted?
    end

    def include_permitted?
      object.respond_to?(:permitted?)
    end

    def include_start?
      object.start && include_steps?
    end

    def include_steps?
      !include_completed?
    end

    def required
      object.required
    end

    def include_required?
      object.respond_to?(:required)
    end

    def user
      object.user
    end
    
    def categories
      begin
        site = ::Site.new(scope)
        ::ActiveModel::ArraySerializer.new(site.categories, each_serializer: BasicCategorySerializer)
      rescue => e
        puts "HERE IS THE ERROR: #{e.inspect}"
      end
    end
    
    def uncategorized_category_id
      SiteSetting.uncategorized_category_id
    end
  end

  ::WizardStepSerializer.class_eval do
    attributes :permitted, :permitted_message

    def title
      return PrettyText.cook(object.title) if object.title
      PrettyText.cook(I18n.t("#{object.key || i18n_key}.title", default: ''))
    end

    def description
      return object.description if object.description
      PrettyText.cook(I18n.t("#{object.key || i18n_key}.description", default: '', base_url: Discourse.base_url))
    end

    def permitted
      object.permitted
    end
    
    def permitted_message
      object.permitted_message
    end
  end

  ::WizardFieldSerializer.class_eval do
    attributes :dropdown_none, :image, :file_types, :limit, :property

    def label
      return object.label if object.label.present?
      I18n.t("#{object.key || i18n_key}.label", default: '')
    end

    def description
      return object.description if object.description.present?
      I18n.t("#{object.key || i18n_key}.description", default: '', base_url: Discourse.base_url)
    end

    def image
      object.image
    end

    def include_image?
      object.image.present?
    end

    def placeholder
      I18n.t("#{object.key || i18n_key}.placeholder", default: '')
    end

    def dropdown_none
      object.dropdown_none
    end

    def file_types
      object.file_types
    end
    
    def limit
      object.limit
    end
    
    def property
      object.property
    end
  end

  ::UsersController.class_eval do
    def wizard_path
      if custom_wizard_redirect = current_user.custom_fields['redirect_to_wizard']
        "#{Discourse.base_url}/w/#{custom_wizard_redirect.dasherize}"
      else
        "#{Discourse.base_url}/wizard"
      end
    end
  end

  module InvitesControllerCustomWizard
    def path(url)
      if Wizard.user_requires_completion?(@user)
        wizard_id = @user.custom_fields['custom_wizard_redirect']

        if wizard_id && url != '/'
          CustomWizard::Wizard.set_submission_redirect(@user, wizard_id, url)
          url = "/w/#{wizard_id.dasherize}"
        end
      end
      super(url)
    end

    private def post_process_invite(user)
      super(user)
      @user = user
    end
  end
  
  require_dependency 'invites_controller'
  class ::InvitesController
    prepend InvitesControllerCustomWizard
  end
  
  require_dependency 'application_controller'
  class ::ApplicationController
    before_action :redirect_to_wizard_if_required, if: :current_user

    def redirect_to_wizard_if_required
      wizard_id = current_user.custom_fields['redirect_to_wizard']
      @excluded_routes ||= SiteSetting.wizard_redirect_exclude_paths.split('|') + ['/w/']
      url = request.referer || request.original_url

      if request.format === 'text/html' && !@excluded_routes.any? {|str| /#{str}/ =~ url} && wizard_id
        if request.referer !~ /\/w\// && request.referer !~ /\/invites\//
          CustomWizard::Wizard.set_submission_redirect(current_user, wizard_id, request.referer)
        end

        if CustomWizard::Wizard.exists?(wizard_id)
          redirect_to "/w/#{wizard_id.dasherize}"
        end
      end
    end
  end

  add_to_serializer(:current_user, :redirect_to_wizard) {object.custom_fields['redirect_to_wizard']}

  ## TODO limit this to the first admin
  SiteSerializer.class_eval do
    attributes :complete_custom_wizard

    def include_wizard_required?
      scope.is_admin? && Wizard.new(scope.user).requires_completion?
    end

    def complete_custom_wizard
      if scope.user && requires_completion = CustomWizard::Wizard.prompt_completion(scope.user)
        requires_completion.map {|w| {name: w[:name], url: "/w/#{w[:id]}"}}
      end
    end

    def include_complete_custom_wizard?
      complete_custom_wizard.present?
    end
  end

  DiscourseEvent.on(:user_approved) do |user|
    if wizard_id = CustomWizard::Wizard.after_signup
      CustomWizard::Wizard.set_wizard_redirect(user, wizard_id)
    end
  end
  
  module CustomWizardExtraLocalesController
    def show
      if request.referer && URI(request.referer).path.include?('/w/')
        bundle = params[:bundle]
          
        if params[:v]&.size == 32
          hash = ExtraLocalesController.bundle_js_hash(bundle)
          immutable_for(1.year) if hash == params[:v]
        end

        render plain: ExtraLocalesController.bundle_js(bundle), content_type: "application/javascript"
      else
        super
      end
    end
  end
  
  class ::ExtraLocalesController
    prepend CustomWizardExtraLocalesController
  end

  DiscourseEvent.trigger(:custom_wizard_ready)
end
