class CustomWizard::TransferController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin

  skip_before_action :check_xhr, :only => [:export]


  def index

  end

  def export

    wizards = params['wizards']
    wizard_objects = []
    wizards.each do
    |w|
      # p w

      wizard_objects.push(PluginStore.get('custom_wizard', w.tr('-', '_')))

    end
    puts 'wizard_objects'
    p wizard_objects
    send_data wizard_objects.to_json, type: "application/json", disposition: 'attachment', filename: 'wizards.json'

  end

  def is_json(string)
    begin
      !!JSON.parse(string)
    rescue
      false
    end
  end

  def import
    file = File.read(params['file'].tempfile)
    fileSize = file.size
    maxFileSize = 512 * 1024
    if maxFileSize < fileSize
      render json: {error: "File too large"}
    end

    unless is_json file
      render json: {error: "File is not a valid json file"}
    end

    jsonObject = JSON.parse file

    countValid = 0
    jsonObject.each do |o|
      # validate whether the given json is a valid "wizard"
      next unless CustomWizard::Template.new(o)
      countValid += 1


      puts 'json entity'
      pluginStoreEntry = PluginStore.new 'custom_wizard'
      #plugin store detects the json object type and sets proper `type_name` for the entry
      pluginStoreEntry.set(o['id'], o)

    end

    if countValid == 0
      render json: {error: "File doesn't contain any valid wizards"}
    else
      render json: {success: "Wizards imported successfully"}
    end
  end
  # admin/wizards/transfer/import

end
