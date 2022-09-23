# frozen_string_literal: true
# name: discourse-custom-wizard
# about: Forms for Discourse. Better onboarding, structured posting, data enrichment, automated actions and much more.
# version: 2.0.0
# authors: Angus McLeod, Faizaan Gagan, Robert Barrow, Keegan George, Kaitlin Maddever
# url: https://github.com/paviliondev/discourse-custom-wizard
# contact_emails: development@pavilion.tech
# subscription_url: https://coop.pavilion.tech

gem 'liquid', '5.0.1', require: true
register_asset 'stylesheets/common/admin.scss'
register_asset 'stylesheets/common/wizard.scss'

enabled_site_setting :custom_wizard_enabled

if respond_to?(:register_svg_icon)
  register_svg_icon "far-calendar"
  register_svg_icon "chevron-right"
  register_svg_icon "chevron-left"
  register_svg_icon "save"
  register_svg_icon "sliders-h"
  register_svg_icon "calendar"
  register_svg_icon "check"
  register_svg_icon "times"
  register_svg_icon "clock"
  register_svg_icon "link"
  register_svg_icon "comment-alt"
  register_svg_icon "far-life-ring"
  register_svg_icon "arrow-right"
  register_svg_icon "bolt"
end

after_initialize do
  %w[
    ../lib/custom_wizard/engine.rb
    ../config/routes.rb
    ../app/controllers/custom_wizard/admin/admin.rb
    ../app/controllers/custom_wizard/admin/wizard.rb
    ../app/controllers/custom_wizard/admin/submissions.rb
    ../app/controllers/custom_wizard/admin/api.rb
    ../app/controllers/custom_wizard/admin/logs.rb
    ../app/controllers/custom_wizard/admin/manager.rb
    ../app/controllers/custom_wizard/admin/custom_fields.rb
    ../app/controllers/custom_wizard/wizard.rb
    ../app/controllers/custom_wizard/steps.rb
    ../app/controllers/custom_wizard/realtime_validations.rb
    ../app/jobs/regular/refresh_api_access_token.rb
    ../app/jobs/regular/set_after_time_wizard.rb
    ../lib/custom_wizard/validators/template.rb
    ../lib/custom_wizard/validators/update.rb
    ../lib/custom_wizard/action_result.rb
    ../lib/custom_wizard/action.rb
    ../lib/custom_wizard/builder.rb
    ../lib/custom_wizard/cache.rb
    ../lib/custom_wizard/custom_field.rb
    ../lib/custom_wizard/field.rb
    ../lib/custom_wizard/realtime_validation.rb
    ../lib/custom_wizard/realtime_validations/result.rb
    ../lib/custom_wizard/realtime_validations/similar_topics.rb
    ../lib/custom_wizard/mapper.rb
    ../lib/custom_wizard/log.rb
    ../lib/custom_wizard/step_updater.rb
    ../lib/custom_wizard/step.rb
    ../lib/custom_wizard/submission.rb
    ../lib/custom_wizard/subscription.rb
    ../lib/custom_wizard/template.rb
    ../lib/custom_wizard/wizard.rb
    ../lib/custom_wizard/api/api.rb
    ../lib/custom_wizard/api/authorization.rb
    ../lib/custom_wizard/api/endpoint.rb
    ../lib/custom_wizard/api/log_entry.rb
    ../lib/custom_wizard/liquid_extensions/first_non_empty.rb
    ../lib/custom_wizard/exceptions/exceptions.rb
    ../app/serializers/custom_wizard/api/authorization_serializer.rb
    ../app/serializers/custom_wizard/api/basic_endpoint_serializer.rb
    ../app/serializers/custom_wizard/api/endpoint_serializer.rb
    ../app/serializers/custom_wizard/api/log_serializer.rb
    ../app/serializers/custom_wizard/api_serializer.rb
    ../app/serializers/custom_wizard/basic_api_serializer.rb
    ../app/serializers/custom_wizard/basic_wizard_serializer.rb
    ../app/serializers/custom_wizard/custom_field_serializer.rb
    ../app/serializers/custom_wizard/wizard_field_serializer.rb
    ../app/serializers/custom_wizard/wizard_step_serializer.rb
    ../app/serializers/custom_wizard/wizard_serializer.rb
    ../app/serializers/custom_wizard/log_serializer.rb
    ../app/serializers/custom_wizard/submission_serializer.rb
    ../app/serializers/custom_wizard/realtime_validation/similar_topics_serializer.rb
    ../lib/custom_wizard/extensions/extra_locales_controller.rb
    ../lib/custom_wizard/extensions/invites_controller.rb
    ../lib/custom_wizard/extensions/users_controller.rb
    ../lib/custom_wizard/extensions/tags_controller.rb
    ../lib/custom_wizard/extensions/guardian.rb
    ../lib/custom_wizard/extensions/custom_field/preloader.rb
    ../lib/custom_wizard/extensions/custom_field/serializer.rb
    ../lib/custom_wizard/extensions/custom_field/extension.rb
    ../lib/custom_wizard/extensions/discourse_tagging.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  Liquid::Template.error_mode = :strict

  # preloaded category custom fields
  %w[
    create_topic_wizard
  ].each do |custom_field|
    Site.preloaded_category_custom_fields << custom_field
  end

  Liquid::Template.register_filter(::CustomWizard::LiquidFilter::FirstNonEmpty)

  add_to_class(:topic, :wizard_submission_id) do
    custom_fields['wizard_submission_id']
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
        CustomWizard::Wizard.set_user_redirect(wizard.id, user)
      end
    end

    !!custom_redirect
  end

  add_to_class(:user, :redirect_to_wizard) do
    if custom_fields['redirect_to_wizard'].present?
      custom_fields['redirect_to_wizard']
    else
      nil
    end
  end

  add_to_class(:users_controller, :wizard_path) do
    if custom_wizard_redirect = current_user.redirect_to_wizard
      "#{Discourse.base_url}/w/#{custom_wizard_redirect.dasherize}"
    else
      "#{Discourse.base_url}/wizard"
    end
  end

  add_to_serializer(:current_user, :redirect_to_wizard) do
    object.redirect_to_wizard
  end

  on(:user_approved) do |user|
    if wizard = CustomWizard::Wizard.after_signup(user)
      CustomWizard::Wizard.set_user_redirect(wizard.id, user)
    end
  end

  add_to_class(:application_controller, :redirect_to_wizard_if_required) do
    @excluded_routes ||= SiteSetting.wizard_redirect_exclude_paths.split('|') + ['/w/']
    url = request.referer || request.original_url
    excluded_route = @excluded_routes.any? { |str| /#{str}/ =~ url }
    not_api = request.format === 'text/html'

    if not_api && !excluded_route
      wizard_id = current_user.redirect_to_wizard

      if CustomWizard::Template.can_redirect_users?(wizard_id)
        if url !~ /\/w\// && url !~ /\/invites\//
          CustomWizard::Wizard.set_wizard_redirect(current_user, wizard_id, url)
        end

        redirect_to "/w/#{wizard_id.dasherize}"
      end
    end
  end

  add_to_serializer(:site, :include_wizard_required?) do
    scope.is_admin? && Wizard.new(scope.user).requires_completion?
  end

  add_to_serializer(:site, :complete_custom_wizard) do
    if scope.user && requires_completion = CustomWizard::Wizard.prompt_completion(scope.user)
      requires_completion.map { |w| { name: w[:name], url: "/w/#{w[:id]}" } }
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
  ::Guardian.prepend CustomWizardGuardian

  full_path = "#{Rails.root}/plugins/discourse-custom-wizard/assets/stylesheets/wizard/wizard_custom.scss"
  if Stylesheet::Importer.respond_to?(:plugin_assets)
    Stylesheet::Importer.plugin_assets['wizard_custom'] = Set[full_path]
  else
    # legacy method, Discourse 2.7.0.beta5 and below
    DiscoursePluginRegistry.register_asset(full_path, {}, "wizard_custom")
    Stylesheet::Importer.register_import("wizard_custom") do
      import_files(DiscoursePluginRegistry.stylesheets["wizard_custom"])
    end
  end

  CustomWizard::CustomField::CLASSES.keys.each do |klass|
    class_constant = klass.to_s.classify.constantize

    add_model_callback(klass, :after_initialize) do
      if CustomWizard::CustomField.enabled?
        CustomWizard::CustomField.list_by(:klass, klass.to_s).each do |field|
          class_constant.register_custom_field_type(field[:name], field[:type].to_sym)
        end
      end
    end

    class_constant.singleton_class.prepend CustomWizardCustomFieldPreloader
    class_constant.singleton_class.prepend CustomWizardCustomFieldExtension
  end

  CustomWizard::CustomField.serializers.each do |serializer_klass|
    "#{serializer_klass}_serializer".classify.constantize.prepend CustomWizardCustomFieldSerializer
  end

  reloadable_patch do |plugin|
    ::TagsController.prepend CustomWizardTagsController
    ::DiscourseTagging.singleton_class.prepend CustomWizardDiscourseTagging
  end

  DiscourseEvent.trigger(:custom_wizard_ready)
end
