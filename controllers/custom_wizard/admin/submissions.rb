class CustomWizard::AdminSubmissionsController < CustomWizard::AdminController
  skip_before_action :preload_json, :check_xhr, only: [:download]
  
  before_action :find_wizard
  
  def index
    render json: ActiveModel::ArraySerializer.new(
      CustomWizard::Wizard.list,
      each_serializer: CustomWizard::BasicWizardSerializer
    )
  end
  
  def show
    result = {}
    
    if wizard = @wizard
      submissions = build_submissions(wizard.id)
      result[:wizard] = CustomWizard::BasicWizardSerializer.new(wizard, root: false)
      result[:submissions] = submissions.as_json
    end  
      
    render_json_dump(result)
  end
  
  def download   
    send_data build_submissions(@wizard.id).to_json,
      filename: "#{Discourse.current_hostname}-wizard-submissions-#{@wizard.name}.json",
      content_type: "application/json",
      disposition: "attachment"
  end
  
  private
  
  def build_submissions(wizard_id)
    rows = PluginStoreRow.where(plugin_name: "#{wizard_id}_submissions").order('id DESC')

    submissions = [*rows].map do |row|
      value = ::JSON.parse(row.value)

      if user = User.find_by(id: row.key)
        username = user.username
      else
        username = I18n.t('admin.wizard.submissions.no_user', id: row.key)
      end

      value.map do |submission|
        {
          username: username
        }.merge!(submission.except("redirect_to"))
      end
    end.flatten
  end
end