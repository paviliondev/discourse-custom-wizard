# frozen_string_literal: true
class CustomWizard::SubmissionSerializer < ApplicationSerializer
  attributes :id,
             :fields,
             :submitted_at

  has_one :user, serializer: ::BasicUserSerializer, embed: :objects

  def include_user?
    object.user.present?
  end

  def fields
    @fields ||= begin
      result = {}

     object.wizard.template['steps'].each do |step|
       step['fields'].each do |field|
         if value = object.fields[field['id']]
           result[field['id']] = {
             value: value,
             type: field['type'],
             label: field['label']
           }
         end
       end
     end

     result
    end
  end
end
