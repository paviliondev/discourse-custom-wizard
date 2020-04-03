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
plugin_asset_path = "#{Rails.root}/plugins/discourse-custom-wizard/assets"
config.assets.paths << "#{plugin_asset_path}/javascripts"
config.assets.paths << "#{plugin_asset_path}/stylesheets/wizard"

if Rails.env.production?
  config.assets.precompile += %w{
    wizard-custom-guest.js
    wizard-custom-lib.js
    wizard-custom.js
    wizard-plugin.js
    wizard-custom-start.js
    wizard-raw-templates.js.erb
    stylesheets/wizard/wizard_autocomplete.scss
    stylesheets/wizard/wizard_custom.scss
    stylesheets/wizard/wizard_composer.scss
    stylesheets/wizard/wizard_variables.scss
    stylesheets/wizard/wizard_custom_mobile.scss
    stylesheets/wizard/wizard_locations.scss
    stylesheets/wizard/wizard_events.scss
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
    '../controllers/application_controller.rb',
    '../controllers/extra_locales_controller.rb',
    '../controllers/invites_controller.rb',
    '../jobs/clear_after_time_wizard.rb',
    '../jobs/refresh_api_access_token.rb',
    '../jobs/set_after_time_wizard.rb',
    '../lib/custom_wizard/builder.rb',
    '../lib/custom_wizard/field.rb',
    '../lib/custom_wizard/step_updater.rb',
    '../lib/custom_wizard/template.rb',
    '../lib/custom_wizard/wizard.rb',
    '../lib/custom_wizard/api/api.rb',
    '../lib/custom_wizard/api/authorization.rb',
    '../lib/custom_wizard/api/endpoint.rb',
    '../lib/custom_wizard/api/log_entry.rb',
    '../lib/wizard/choice.rb',
    '../lib/wizard/field.rb',
    '../lib/wizard/step.rb',
    '../serializers/custom_wizard/api/authorization_serializer.rb',
    '../serializers/custom_wizard/api/basic_endpoint_serializer.rb',
    '../serializers/custom_wizard/api/endpoint_serializer.rb',
    '../serializers/custom_wizard/api/log_serializer.rb',
    '../serializers/custom_wizard/api_serializer.rb',
    '../serializers/custom_wizard/basic_api_serializer.rb',
    '../serializers/custom_wizard/wizard_field_serializer.rb',
    '../serializers/custom_wizard/wizard_step_serializer.rb',
    '../serializers/custom_wizard/wizard_serializer.rb',
    '../serializers/site_serializer.rb'
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  add_class_method(:wizard, :user_requires_completion?) do |user|
    wizard_result = self.new(user).requires_completion?
    return wizard_result if wizard_result

    custom_redirect = false

    if user &&
       user.first_seen_at.blank? &&
       wizard_id = CustomWizard::Wizard.after_signup
       
      wizard = CustomWizard::Wizard.create(user, wizard_id)

      if !wizard.completed? && wizard.permitted?
        custom_redirect = true
        CustomWizard::Wizard.set_wizard_redirect(user, wizard_id)
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

  DiscourseEvent.on(:user_approved) do |user|
    if wizard_id = CustomWizard::Wizard.after_signup
      CustomWizard::Wizard.set_wizard_redirect(user, wizard_id)
    end
  end

  DiscourseEvent.trigger(:custom_wizard_ready)
end
