class CustomWizard::BasicApiSerializer < ::ApplicationSerializer
  attributes :name,
             :title,
             :endpoints

  def endpoints
    if endpoints = CustomWizard::Api::Endpoint.list(object.name)
      ActiveModel::ArraySerializer.new(
       endpoints,
       each_serializer: CustomWizard::Api::BasicEndpointSerializer
      )
    end
  end
end
