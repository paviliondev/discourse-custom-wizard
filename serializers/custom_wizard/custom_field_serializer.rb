class CustomWizard::CustomFieldSerializer < ApplicationSerializer
  attributes :klass, :name, :type, :serializers
end