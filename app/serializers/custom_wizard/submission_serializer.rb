# frozen_string_literal: true
class CustomWizard::SubmissionSerializer < ApplicationSerializer
  attributes :id, :fields, :submitted_at, :user

  def include_user?
    object.wizard.user.present?
  end

  def user
    ::BasicUserSerializer.new(object.wizard.user, root: false).as_json
  end

  def fields
    @fields ||=
      begin
        result = {}

        object.wizard.template["steps"].each do |step|
          step["fields"].each do |field|
            if value = object.fields[field["id"]]
              result[field["id"]] = { value: value, type: field["type"], label: field["label"] }
            end
          end
        end

        result
      end
  end
end
