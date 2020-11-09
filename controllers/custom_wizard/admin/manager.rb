class CustomWizard::AdminManagerController < CustomWizard::AdminController
  skip_before_action :check_xhr, only: [:export]
  before_action :get_wizard_ids, except: [:import]

  def export
    templates = []
    
    @wizard_ids.each do |wizard_id|
      if template = CustomWizard::Template.find(wizard_id)
        templates.push(template)
      end
    end
    
    if templates.empty?
      return render_error(I18n.t('wizard.export.error.invalid_wizards'))
    end
    
    basename = SiteSetting.title.parameterize || 'discourse'
    time = Time.now.to_i 
    filename = "#{basename}-wizards-#{time}.json"

    send_data templates.to_json,
      type: "application/json",
      disposition: 'attachment',
      filename: filename
  end

  def import
    file = File.read(params['file'].tempfile)
    
    if file.nil?
      return render_error(I18n.t('wizard.export.error.no_file'))
    end

    file_size = file.size
    max_file_size = 512 * 1024
    
    if max_file_size < file_size
      return render_error(I18n.t('wizard.import.error.file_large'))
    end
        
    begin
      template_json = JSON.parse file
    rescue JSON::ParserError
      return render_error(I18n.t('wizard.import.error.invalid_json'))
    end
    
    imported = []
    failures = []
    
    template_json.each do |json|
      template = CustomWizard::Template.new(json)
      template.save(skip_jobs: true, create: true)
            
      if template.errors.any?
        failures.push(
          id: json['id'],
          messages: template.errors.full_messages.join(', ')
        )
      else
        imported.push(
          id: json['id'],
          name: json['name']
        )
      end
    end

    render json: success_json.merge(
      imported: imported,
      failures: failures
    )
  end
  
  def destroy
    destroyed = []
    failures = []
    
    @wizard_ids.each do |wizard_id|
      template = CustomWizard::Template.find(wizard_id)
      
      if template && CustomWizard::Template.remove(wizard_id)
        destroyed.push(
          id: wizard_id,
          name: template['name']
        )
      else
        failures.push(
          id: wizard_id,
          messages: I18n.t("wizard.destroy.error.#{template ? 'default' : 'no_template'}")
        )
      end
    end
    
    render json: success_json.merge(
      destroyed: destroyed,
      failures: failures
    )
  end
  
  private
  
  def get_wizard_ids
    if params['wizard_ids'].blank?
      return render_error(I18n.t('wizard.export.error.select_one'))
    end
    
    wizard_ids = []
    
    params['wizard_ids'].each do |wizard_id|
      begin
        wizard_ids.push(wizard_id.underscore)
      rescue
        #
      end
    end
    
    if wizard_ids.empty?
      return render_error(I18n.t('wizard.export.error.invalid_wizards'))
    end
    
    @wizard_ids = wizard_ids
  end
end
