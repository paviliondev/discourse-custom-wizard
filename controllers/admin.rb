class CustomWizard::AdminController < ::ApplicationController
  before_filter :ensure_logged_in
  before_filter :ensure_admin

  def index
    render nothing: true
  end

  def save
    params.require(:name)
    params.permit(:steps)

    wizard = { name: params[:name] }

    wizard['steps'] = params[:steps] if params[:steps]

    key = params[:name].downcase

    PluginStore.set('custom_wizards', key, wizard)

    render json: success_json
  end

  def remove
    params.require(:name)

    key = params[:name].downcase

    PluginStore.remove('custom_wizards', key)

    render json: success_json
  end

  def find
    params.require(:name)

    key = params[:name].downcase

    wizard = PluginStore.get('custom_wizards', key)

    render json: success_json.merge(wizard: wizard)
  end

  def all
    rows = PluginStoreRow.where(plugin_name: 'custom_wizards')

    wizards = rows ? [*rows].map do |r|
      CustomWizard::Wizard.new(r.value)
    end : []

    render json: success_json.merge(wizards: wizards)
  end
end
