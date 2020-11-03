class CustomWizard::AdminSubmissionsController < CustomWizard::AdminController
  skip_before_action :preload_json, :check_xhr, only: [:download]
  before_action :find_wizard, except: [:index]
  
  def index
    render json: ActiveModel::ArraySerializer.new(
      CustomWizard::Wizard.list(current_user),
      each_serializer: CustomWizard::BasicWizardSerializer
    )
  end
  
  def show
    render_json_dump(
      wizard: CustomWizard::BasicWizardSerializer.new(@wizard, root: false),
      submissions: build_submissions.as_json
    )
  end
  
  def download   
    send_data build_submissions.to_json,
      filename: "#{Discourse.current_hostname}-wizard-submissions-#{@wizard.name}.json",
      content_type: "application/json",
      disposition: "attachment"
  end
  
  private
  
  def build_submissions
    PluginStoreRow.where(plugin_name: "#{@wizard.id}_submissions")
      .order('id DESC')
      .map do |row|
        value = ::JSON.parse(row.value)
        
        if user = User.find_by(id: row.key)
          username = user.username
        else
          username = I18n.t('admin.wizard.submissions.no_user', id: row.key)
        end
        
        value.map do |v|
          { username: username }.merge!(v.except("redirect_to"))
        end
      end.flatten
  end
end