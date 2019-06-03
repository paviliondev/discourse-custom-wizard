class CustomWizard::ApiSerializer < ApplicationSerializer
  attributes :name,
             :title,
             :authorization,
             :endpoints

  def authorization
    if authorization = CustomWizard::Api::Authorization.get(object.name)
      CustomWizard::Api::AuthorizationSerializer.new(
        authorization,
        root: false
      )
    end
  end

  def endpoints
    if endpoints = CustomWizard::Api::Endpoint.list(object.name)
      ActiveModel::ArraySerializer.new(
       endpoints,
       each_serializer: CustomWizard::Api::EndpointSerializer
      )
    end
  end
end
