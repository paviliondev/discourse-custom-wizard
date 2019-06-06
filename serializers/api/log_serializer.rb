class CustomWizard::Api::LogSerializer < ApplicationSerializer
  attributes :log_id,
             :time,
             :status,
             :endpoint_url,
             :error
end
