class CustomWizard::Api
  include ActiveModel::SerializerSupport

  attr_accessor :service

  def initialize(service)
    @service = service
  end

  def self.list
    PluginStoreRow.where("plugin_name LIKE 'custom_wizard_api_%' AND key = 'authorization'")
      .map do |record|
        self.new(record['plugin_name'].split('_').last)
      end
  end
end
