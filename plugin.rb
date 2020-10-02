# name: discourse-custom-wizard
# about: Create custom wizards
# version: 0.2
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-custom-wizard

register_asset 'stylesheets/common/wizard-admin.scss'
register_asset 'stylesheets/common/wizard-mapper.scss'
register_asset 'lib/jquery.timepicker.min.js'
register_asset 'lib/jquery.timepicker.scss'

enabled_site_setting :custom_wizard_enabled

config = Rails.application.config
plugin_asset_path = "#{Rails.root}/plugins/discourse-custom-wizard/assets"
config.assets.paths << "#{plugin_asset_path}/javascripts"
config.assets.paths << "#{plugin_asset_path}/stylesheets/wizard"

if Rails.env.production?
  config.assets.precompile += %w{
    wizard-custom-guest.js
    wizard-custom-globals.js
    wizard-custom.js
    wizard-custom-start.js
    wizard-plugin.js.erb
    wizard-raw-templates.js.erb
  }
end

if respond_to?(:register_svg_icon)
  register_svg_icon "far-calendar"
  register_svg_icon "chevron-right"
  register_svg_icon "chevron-left"
end

after_initialize do
  %w[
    ../lib/custom_wizard/engine.rb
    ../config/routes.rb
    ../controllers/custom_wizard/admin/admin.rb
    ../controllers/custom_wizard/admin/wizard.rb
    ../controllers/custom_wizard/admin/submissions.rb
    ../controllers/custom_wizard/admin/api.rb
    ../controllers/custom_wizard/admin/logs.rb
    ../controllers/custom_wizard/wizard.rb
    ../controllers/custom_wizard/steps.rb
    ../controllers/custom_wizard/transfer.rb
    ../jobs/clear_after_time_wizard.rb
    ../jobs/refresh_api_access_token.rb
    ../jobs/set_after_time_wizard.rb
    ../lib/custom_wizard/action_result.rb
    ../lib/custom_wizard/action.rb
    ../lib/custom_wizard/builder.rb
    ../lib/custom_wizard/field.rb
    ../lib/custom_wizard/mapper.rb
    ../lib/custom_wizard/log.rb
    ../lib/custom_wizard/step_updater.rb
    ../lib/custom_wizard/validator.rb
    ../lib/custom_wizard/wizard.rb
    ../lib/custom_wizard/api/api.rb
    ../lib/custom_wizard/api/authorization.rb
    ../lib/custom_wizard/api/endpoint.rb
    ../lib/custom_wizard/api/log_entry.rb
    ../serializers/custom_wizard/api/authorization_serializer.rb
    ../serializers/custom_wizard/api/basic_endpoint_serializer.rb
    ../serializers/custom_wizard/api/endpoint_serializer.rb
    ../serializers/custom_wizard/api/log_serializer.rb
    ../serializers/custom_wizard/api_serializer.rb
    ../serializers/custom_wizard/basic_api_serializer.rb
    ../serializers/custom_wizard/basic_wizard_serializer.rb
    ../serializers/custom_wizard/wizard_field_serializer.rb
    ../serializers/custom_wizard/wizard_step_serializer.rb
    ../serializers/custom_wizard/wizard_serializer.rb
    ../serializers/custom_wizard/log_serializer.rb
    ../extensions/extra_locales_controller.rb
    ../extensions/invites_controller.rb
    ../extensions/users_controller.rb
    ../extensions/wizard_field.rb
    ../extensions/wizard_step.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  add_class_method(:wizard, :user_requires_completion?) do |user|
    wizard_result = self.new(user).requires_completion?
    return wizard_result if wizard_result

    custom_redirect = false

    if user &&
       user.first_seen_at.blank? &&
       wizard = CustomWizard::Wizard.after_signup(user)

      if !wizard.completed?
        custom_redirect = true
        CustomWizard::Wizard.set_wizard_redirect(wizard.id, user)
      end
    end

    !!custom_redirect
  end
    
  add_to_class(:users_controller, :wizard_path) do
    if custom_wizard_redirect = current_user.custom_fields['redirect_to_wizard']
      "#{Discourse.base_url}/w/#{custom_wizard_redirect.dasherize}"
    else
      "#{Discourse.base_url}/wizard"
    end
  end

  add_to_serializer(:current_user, :redirect_to_wizard) do
    object.custom_fields['redirect_to_wizard']
  end

  on(:user_approved) do |user|
    if wizard = CustomWizard::Wizard.after_signup(user)
      CustomWizard::Wizard.set_wizard_redirect(wizard.id, user)
    end
  end
  
  add_to_class(:application_controller, :redirect_to_wizard_if_required) do
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
  
  add_to_serializer(:site, :include_wizard_required?) do
    scope.is_admin? && Wizard.new(scope.user).requires_completion?
  end
  
  add_to_serializer(:site, :complete_custom_wizard) do
    if scope.user && requires_completion = CustomWizard::Wizard.prompt_completion(scope.user)
      requires_completion.map {|w| { name: w[:name], url: "/w/#{w[:id]}"} }
    end
  end

  add_to_serializer(:site, :include_complete_custom_wizard?) do
    complete_custom_wizard.present?
  end
  
  add_model_callback(:application_controller, :before_action) do
    redirect_to_wizard_if_required if current_user
  end
  
  ::ExtraLocalesController.prepend ExtraLocalesControllerCustomWizard
  ::InvitesController.prepend InvitesControllerCustomWizard
  ::UsersController.prepend CustomWizardUsersController
  ::Wizard::Field.prepend CustomWizardFieldExtension
  ::Wizard::Step.prepend CustomWizardStepExtension
  
  CustomWizard::Wizard.register_styles
  
  DiscourseEvent.trigger(:custom_wizard_ready)
end
