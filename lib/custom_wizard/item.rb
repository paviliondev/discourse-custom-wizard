class CustomWizard::Item
  WIZARD_ITEM = 'wizard_item'.freeze

  def initialize(name, value)
    @name = name
    @value = value
  end

  def save
    PluginStore.set(WIZARD_ITEM, @name, @value)
  end

  def self.search(params)
    items = PluginStore.get(WIZARD_ITEM, params[:name])
    items ? items.filter{ |string| string.downcase.include?(params[:value].downcase) }.take(params[:limit] || 5)
          : []
  end
end
