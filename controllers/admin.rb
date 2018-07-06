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

    existing = PluginStore.get('custom_wizard', wizard['id']) || {}

    new_time = false

    error = nil

    if wizard["id"].blank?
      error = 'id_required'
    elsif wizard["name"].blank?
      error = 'name_required'
    elsif wizard["steps"].blank?
      error = 'steps_required'
    elsif wizard["after_time"]
      if !wizard["after_time_scheduled"] && !existing["after_time_scheduled"]
        error = 'after_time_need_time'
      else
        after_time_scheduled = Time.parse(wizard["after_time_scheduled"]).utc

        new_time = existing['after_time_scheduled'] ?
                   after_time_scheduled != Time.parse(existing['after_time_scheduled']).utc :
                   true

        begin
          if new_time && after_time_scheduled < Time.now.utc
            error = 'after_time_invalid'
          end
        rescue ArgumentError
          error = 'after_time_invalid'
        end
      end
    end

    return render json: { error: error } if error

    wizard["steps"].each do |s|
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

          if f["type"].blank?
            error = 'type_required'
            break
          end

          if f["type"] === 'dropdown'
            choices = f["choices"]
            if (!choices || choices.length < 1) && !f["choices_key"] && !f["choices_preset"]
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

    ## end of error checks

    wizard['steps'].each do |s|
      s['description'] = PrettyText.cook(s['raw_description']) if s['raw_description']
    end

    if wizard['after_time'] && new_time
      Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard['id'])
      Jobs.enqueue_at(after_time_scheduled, :set_after_time_wizard, wizard_id: wizard['id'])
    end

    if existing['after_time'] && !wizard['after_time']
      Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard['id'])
      Jobs.enqueue(:clear_after_time_wizard, wizard_id: wizard['id'])
    end

    PluginStore.set('custom_wizard', wizard["id"], wizard)

    render json: success_json
  end

  def remove
    params.require(:id)

    wizard = PluginStore.get('custom_wizard', params[:id])

    if wizard['after_time']
      Jobs.cancel_scheduled_job(:set_after_time_wizard)
      Jobs.enqueue(:clear_after_time_wizard, wizard_id: wizard['id'])
    end

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

    rows = PluginStoreRow.where(plugin_name: "#{params[:wizard_id]}_submissions").order('id DESC')

    all_submissions = [*rows].map do |r|
      submissions = ::JSON.parse(r.value)

      if user = User.find_by(id: r.key)
        username = user.username
      else
        username = I18n.t('admin.wizard.submissions.no_user', id: r.key)
      end

      submissions.map { |s| { username: username }.merge!(s.except("redirect_to")) }
    end.flatten

    render json: success_json.merge(submissions: all_submissions)
  end
end
