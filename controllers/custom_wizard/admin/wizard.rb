# frozen_string_literal: true
class CustomWizard::AdminWizardController < CustomWizard::AdminController
  before_action :find_wizard, only: [:show, :remove]

  def index
    render_json_dump(
      wizard_list: ActiveModel::ArraySerializer.new(
        CustomWizard::Wizard.list(current_user),
        each_serializer: CustomWizard::BasicWizardSerializer
      ),
      field_types: CustomWizard::Field.types,
      realtime_validations: CustomWizard::RealtimeValidation.types,
      custom_fields: custom_field_list
    )
  end

  def show
    params.require(:wizard_id)

    if data = CustomWizard::Template.find(params[:wizard_id].underscore)
      render json: data.as_json
    else
      render json: { none: true }
    end
  end

  def remove
    if CustomWizard::Template.remove(@wizard.id)
      render json: success_json
    else
      render json: failed_json
    end
  end

  def save
    template = CustomWizard::Template.new(save_wizard_params.to_h)
    wizard_id = template.save(create: params[:create])

    if template.errors.any?
      render json: failed_json.merge(backend_validation_error: template.errors.full_messages.join("\n\n"))
    else
      render json: success_json.merge(wizard_id: wizard_id)
    end
  end

  private

  def mapped_params
    [
      :type,
      :connector,
      :output,
      :output_type,
      :output_connector,
      pairs: [
        :index,
        :key,
        :key_type,
        :value,
        :value_type,
        :connector,
        value: [],
        key: [],
      ],
      output: [],
    ]
  end

  def save_wizard_params
    params.require(:wizard).permit(
      :id,
      :name,
      :background,
      :save_submissions,
      :multiple_submissions,
      :after_signup,
      :after_time,
      :after_time_scheduled,
      :required,
      :prompt_completion,
      :restart_on_revisit,
      :resume_on_revisit,
      :theme_id,
      permitted: mapped_params,
      steps: [
        :id,
        :index,
        :title,
        :key,
        :banner,
        :raw_description,
        :required_data_message,
        :force_final,
        required_data: mapped_params,
        permitted_params: mapped_params,
        condition: mapped_params,
        fields: [
          :id,
          :index,
          :label,
          :image,
          :description,
          :required,
          :key,
          :type,
          :min_length,
          :max_length,
          :char_counter,
          :file_types,
          :format,
          :limit,
          :property,
          :preview_template,
          :placeholder,
          prefill: mapped_params,
          content: mapped_params,
          condition: mapped_params,
          index: mapped_params,
          validations: {},
          tag_groups: [],
        ]
      ],
      actions: [
        :id,
        :run_after,
        :type,
        :code,
        :skip_redirect,
        :suppress_notifications,
        :post,
        :post_builder,
        :post_template,
        :notification_level,
        :api,
        :api_endpoint,
        :api_body,
        :wizard_user,
        title: mapped_params,
        category: mapped_params,
        tags: mapped_params,
        custom_fields: mapped_params,
        visible: mapped_params,
        required: mapped_params,
        recipient: mapped_params,
        categories: mapped_params,
        mute_remainder: mapped_params,
        profile_updates: mapped_params,
        group: mapped_params,
        url: mapped_params,
        name: mapped_params,
        slug: mapped_params,
        color: mapped_params,
        text_color: mapped_params,
        parent_category_id: mapped_params,
        permissions: mapped_params,
        full_name: mapped_params,
        bio_raw: mapped_params,
        usernames: mapped_params,
        owner_usernames: mapped_params,
        grant_trust_level: mapped_params,
        mentionable_level: mapped_params,
        messageable_level: mapped_params,
        visibility_level: mapped_params,
        members_visibility_level: mapped_params
      ]
    )
  end
end
