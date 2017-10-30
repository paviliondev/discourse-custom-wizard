class CustomWizard::AdminController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin

  def index
    render nothing: true
  end

  def field_types
    render json: { types: CustomWizard::Field.types }
  end

  def save
    params.require(:wizard)

    wizard = ::JSON.parse(params[:wizard])

    error = nil

    if !wizard["id"] || wizard["id"].empty?
      error = 'id_required'
    elsif !wizard["name"] || wizard["name"].empty?
      error = 'name_required'
    elsif !wizard["steps"] || wizard["steps"].empty?
      error = 'steps_required'
    end

    return render json: { error: error } if error

    wizard["steps"].each do |s|
      puts "HERE IS THE ID: #{s["id"]}"
      if s["id"].blank?
        error = 'id_required'
        break
      end

      if s["fields"] && s["fields"].present?
        s["fields"].each do |f|
          if f["id"].blank?
            error = 'id_required'
            break
          end

          if f["type"] === 'dropdown'
            choices = f["choices"]
            if (!choices || choices.length < 1) && !f["choices_key"] && !f["choices_categories"]
              error = 'field.need_choices'
              break
            end
          end
        end
      end

      if s["actions"] && s["actions"].present?
        s["actions"].each do |a|
          if a["id"].blank?
            error = 'id_required'
            break
          end
        end
      end
    end

    return render json: { error: error } if error

    PluginStore.set('custom_wizard', wizard["id"], wizard)

    render json: success_json
  end

  def remove
    params.require(:id)

    PluginStore.remove('custom_wizard', params[:id])

    render json: success_json
  end

  def find_wizard
    params.require(:wizard_id)

    wizard = PluginStore.get('custom_wizard', params[:wizard_id].underscore)

    render json: success_json.merge(wizard: wizard)
  end

  def custom_wizards
    rows = PluginStoreRow.where(plugin_name: 'custom_wizard').order(:id)

    wizards = [*rows].map { |r| CustomWizard::Template.new(r.value) }

    render json: success_json.merge(wizards: wizards)
  end

  def submissions
    params.require(:wizard_id)

    rows = PluginStoreRow.where(plugin_name: "#{params[:wizard_id]}_submissions").order(:id)

    submissions = [*rows].map { |r| ::JSON.parse(r.value) }.flatten

    render json: success_json.merge(submissions: submissions)
  end
end
