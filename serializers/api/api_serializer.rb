class CustomWizard::ApiSerializer < ApplicationSerializer
  attributes :service,
             :authorization,
             :endpoints

  def authorization
    CustomWizard::Api::AuthorizationSerializer.new(
      CustomWizard::Api::Authorization.get(object.service),
      root: false
    )
  end

  def endpoints
   ActiveModel::ArraySerializer.new(
     CustomWizard::Api::Endpoint.list,
     each_serializer: CustomWizard::Api::EndpointSerializer
   )
  end
end
