class CustomWizard::AdminController < ::ApplicationController
  before_filter :ensure_logged_in
  before_filter :ensure_admin

  def index
    render nothing: true
  end

  def save
    params.require(:wizard)

    wizard = ::JSON.parse(params[:wizard])

    wizard["id"] = SecureRandom.hex(8) if !wizard["id"]

    PluginStore.set('custom_wizards', wizard["id"], wizard)

    render json: success_json
  end

  def remove
    params.require(:id)

    PluginStore.remove('custom_wizards', params[:id])

    render json: success_json
  end

  def find
    params.require(:id)

    wizard = PluginStore.get('custom_wizards', params[:id])

    render json: success_json.merge(wizard: wizard)
  end

  def all
    rows = PluginStoreRow.where(plugin_name: 'custom_wizards').order(:id)

    wizards = rows ? [*rows].map do |r|
      CustomWizard::Wizard.new(r.value)
    end : []

    render json: success_json.merge(wizards: wizards)
  end
end
