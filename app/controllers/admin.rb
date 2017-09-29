class CustomWizard::AdminController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin

  def index
    render nothing: true
  end

  def save
    params.require(:wizard)

    wizard = ::JSON.parse(params[:wizard])

    saved = false
    if wizard["existing_id"] && rows = PluginStoreRow.where(plugin_name: 'custom_wizard').order(:id)
      rows.each do |r, i|
        wizard = CustomWizard::Wizard.new(r.value)
        if wizard.id = wizard["existing_id"]
          r.update_all(key: wizard['id'], value: wizard)
          saved = true
        end
      end
    end

    unless saved
      PluginStore.set('custom_wizard', wizard["id"], wizard)
    end

    render json: success_json
  end

  def remove
    params.require(:id)

    PluginStore.remove('custom_wizard', params[:id])

    render json: success_json
  end

  def find
    params.require(:id)

    wizard = PluginStore.get('custom_wizard', params[:id])

    render json: success_json.merge(wizard: wizard)
  end

  def all
    rows = PluginStoreRow.where(plugin_name: 'custom_wizard').order(:id)

    wizards = rows ? [*rows].map do |r|
      CustomWizard::Wizard.new(r.value)
    end : []

    render json: success_json.merge(wizards: wizards)
  end
end
