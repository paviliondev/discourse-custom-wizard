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

      wizard_objects.push(PluginStore.get('custom_wizard',w.tr('-','_')))

    end
    puts 'wizard_objects'
    p wizard_objects
    send_data wizard_objects.to_json ,type: "application/json", disposition:'attachment' ,filename: 'wizards.json'

  end

  def import
    json = params['fileJson']
    jsonObject = JSON.parse json
    puts 'json file'
    # p jsonObject
    jsonObject.each do |o|
      puts 'json entity'
     pluginStoreEntry =  PluginStore.new 'custom_wizard'
      #plugin store detects the json object type and sets proper `type_name` for the entry
      pluginStoreEntry.set(o['id'],o)
    end
  end
  # admin/wizards/transfer/import

end
