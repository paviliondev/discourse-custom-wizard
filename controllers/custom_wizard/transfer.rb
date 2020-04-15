class CustomWizard::TransferController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin
  skip_before_action :check_xhr, :only => [:export]

  def index
  end

  def export
    wizards = params['wizards']
    wizard_objects = []

    if wizards.nil?
      render json: { error: I18n.t('wizard.export.error.select_one') }
      return
    end

    wizards.each do |w|
      wizard_objects.push(PluginStore.get('custom_wizard', w.tr('-', '_')))
    end

    send_data wizard_objects.to_json,
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

    fileSize = file.size
    maxFileSize = 512 * 1024

    if maxFileSize < fileSize
      render json: { error: I18n.t('wizard.import.error.file_large') }
      return
    end
    
    begin
      jsonObject = JSON.parse file
    rescue JSON::ParserError
      render json: { error: I18n.t('wizard.import.error.invalid_json') }
      return
    end
    
    countValid = 0
    success_ids = []
    failed_ids = []
    
    jsonObject.each do |o|
      if !CustomWizard::Wizard.new(o)
        failed_ids.push o['id']
        next
      end
      
      countValid += 1
      pluginStoreEntry = PluginStore.new 'custom_wizard'
      saved = pluginStoreEntry.set(o['id'], o) unless pluginStoreEntry.get(o['id'])
      success_ids.push o['id'] if !!saved
      failed_ids.push o['id'] if !saved
    end

    if countValid == 0
      render json: { error: I18n.t('wizard.import.error.no_valid_wizards') }
    else
      render json: { success: success_ids, failed: failed_ids }
    end
  end
end
