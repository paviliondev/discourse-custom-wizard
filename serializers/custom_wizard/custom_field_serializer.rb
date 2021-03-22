# frozen_string_literal: true
class CustomWizard::CustomFieldSerializer < ApplicationSerializer
  attributes :id, :klass, :name, :type, :serializers
end
