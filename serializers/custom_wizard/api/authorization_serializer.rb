class CustomWizard::Api::AuthorizationSerializer < ::ApplicationSerializer
  attributes :auth_type,
             :auth_url,
             :token_url,
             :client_id,
             :client_secret,
             :authorized,
             :auth_params,
             :access_token,
             :refresh_token,
             :token_expires_at,
             :token_refresh_at,
             :code,
             :username,
             :password
end
