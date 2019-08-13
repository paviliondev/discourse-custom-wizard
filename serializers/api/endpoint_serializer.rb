class CustomWizard::Api::EndpointSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :method,
             :url,
             :content_type,
             :success_codes

  def method
    object.send('method')
  end
end
