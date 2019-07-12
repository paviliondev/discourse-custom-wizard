class CustomWizard::Api::EndpointSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :method,
             :url

  def method
    object.send('method')
  end
end
