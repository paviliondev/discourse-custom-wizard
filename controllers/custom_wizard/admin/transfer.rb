class CustomWizard::AdminTransferController < CustomWizard::AdminController
  skip_before_action :check_xhr, :only => [:export]

  def export
    wizard_ids = params['wizards']
    templates = []

    if wizard_ids.nil?
      render json: { error: I18n.t('wizard.export.error.select_one') }
      return
    end

    wizard_ids.each do |wizard_id|
      if template = CustomWizard::Template.find(wizard_id)
        templates.push(template)
      end
    end

    send_data templates.to_json,
      type: "application/json",
      disposition: 'attachment',
      filename: 'wizards.json'
  end

  def import
    file = File.read(params['file'].tempfile)
    
    if file.nil?
      render json: { error: I18n.t('wizard.import.error.no_file') }
      return
    end

    file_size = file.size
    max_file_size = 512 * 1024
    
    if max_file_size < file_size
      render json: { error: I18n.t('wizard.import.error.file_large') }
      return
    end
        
    begin
      template_json = JSON.parse file
    rescue JSON::ParserError
      render json: { error: I18n.t('wizard.import.error.invalid_json') }
      return
    end
    
    success_ids = []
    failed_ids = []
    
    template_json.each do |t_json|
      template = CustomWizard::Template.new(t_json)
      template.save(skip_jobs: true)
            
      if template.errors.any?
        failed_ids.push t_json['id']
      else
        success_ids.push t_json['id']
      end
    end

    if success_ids.length == 0
      render json: { error: I18n.t('wizard.import.error.no_valid_wizards') }
    else
      render json: { success: success_ids, failed: failed_ids }
    end
  end
end
