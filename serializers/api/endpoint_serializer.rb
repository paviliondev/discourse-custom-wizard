class CustomWizard::Api::EndpointSerializer < ApplicationSerializer
  attributes :id,
             :type,
             :url
end
