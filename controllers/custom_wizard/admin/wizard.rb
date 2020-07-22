class CustomWizard::AdminWizardController < CustomWizard::AdminController
  before_action :find_wizard, only: [:show, :remove]
  
  def index
    render_json_dump(
      wizard_list: ActiveModel::ArraySerializer.new(
        CustomWizard::Wizard.list,
        each_serializer: CustomWizard::BasicWizardSerializer
      ),
      field_types: CustomWizard::Field.types
    )
  end
  
  def show
    params.require(:wizard_id)
    
    if data = CustomWizard::Wizard.find(params[:wizard_id].underscore)
      render json: data.as_json
    else
      render json: { none: true }
    end
  end
  
  def remove
    CustomWizard::Wizard.remove(@wizard.id)
    render json: success_json
  end

  def save
    opts = {}
    opts[:create] = params[:create] if params[:create]
            
    validator = CustomWizard::Validator.new(save_wizard_params.to_h, opts)
    validation = validator.perform

    if validation[:error]
      render json: { error: validation[:error] }
    else      
      if wizard_id = CustomWizard::Wizard.save(validation[:wizard])
        render json: success_json.merge(wizard_id: wizard_id)
      else
        render json: failed_json
      end
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
      :theme_id,
      permitted: mapped_params,
      steps: [
        :id,
        :title,
        :key,
        :banner,
        :raw_description,
        :required_data_message,
        required_data: mapped_params,
        permitted_params: mapped_params,
        fields: [
          :id,
          :label,
          :image,
          :description,
          :required,
          :key,
          :type,
          :min_length,
          :file_types,
          :format,
          :limit,
          :property,
          prefill: mapped_params,
          content: mapped_params
        ]
      ],
      actions: [
        :id,
        :run_after,
        :type,
        :code,
        :skip_redirect,
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
        title: mapped_params,
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
