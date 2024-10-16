# frozen_string_literal: true
class CustomWizard::AdminCustomFieldsController < CustomWizard::AdminController
  requires_plugin "discourse-custom-wizard"

  def index
    render_json_dump(custom_fields: custom_field_list)
  end

  def update
    errors = []
    field_id = nil
    field_data = {}

    if saved_field = CustomWizard::CustomField.find(field_params[:id].to_i)
      CustomWizard::CustomField::ATTRS.each { |attr| field_data[attr] = saved_field.send(attr) }
      field_id = saved_field.id
    end

    CustomWizard::CustomField::ATTRS.each { |attr| field_data[attr] = field_params[attr] }

    field = CustomWizard::CustomField.new(field_id, field_data)

    PluginStoreRow.transaction do
      unless field.save
        field_errors =
          (
            if field.errors.any?
              field.errors.full_messages.join("\n\n")
            else
              I18n.t("wizard.custom_field.error.save_default", name: field.name)
            end
          )
        errors << field_errors
        raise ActiveRecord::Rollback.new
      end
    end

    if errors.any?
      render json: failed_json.merge(messages: errors)
    else
      render json: success_json
    end
  end

  def destroy
    params.require(:name)

    if CustomWizard::CustomField.destroy(params[:name])
      render json: success_json
    else
      render json: failed_json
    end
  end

  private

  def field_params
    params.required(:custom_field).permit(:id, :name, :klass, :type, serializers: [])
  end
end
