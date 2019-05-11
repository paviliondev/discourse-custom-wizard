require 'excon'

class CustomWizard::Authorization
  def self.access_token
    PluginStore.get('custom_wizard', 'access_token') || {}
  end

  def self.set_access_token(data)
    PluginStore.set('custom_wizard', 'access_token', data)
  end

  def self.refresh_token
    PluginStore.get('custom_wizard', 'refresh_token')
  end

  def self.set_refresh_token(token)
    PluginStore.set('custom_wizard', 'refresh_token', token)
  end

  def self.code
    PluginStore.get('custom_wizard', 'code')
  end

  def self.set_code(code)
    PluginStore.set('custom_wizard', 'code', code)
  end

  def self.get_access_token
    body = {
      client_id: SiteSetting.custom_wizard_client_id,
      client_secret: SiteSetting.custom_wizard_client_secret,
      code: CustomWizard::Authorization.code,
      grant_type: 'authorization_code',
      redirect_uri: (Rails.env.development? ? CustomWizard::NGROK_URL : Discourse.base_url) + '/custom_wizard/authorization/callback'
    }

    result = Excon.post(
      "https://api.custom_wizard.com/token",
      :headers => {
        "Content-Type" => "application/x-www-form-urlencoded"
      },
      :body => URI.encode_www_form(body)
    )

    self.handle_token_result(result)
  end

  def self.refresh_access_token
    body = {
      grant_type: 'refresh_token',
      refresh_token: CustomWizard::Authorization.refresh_token
    }

    authorization_string = SiteSetting.custom_wizard_client_id + ':' + SiteSetting.custom_wizard_client_secret

    result = Excon.post(
      "https://api.custom_wizard.com/token",
      :headers => {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Authorization" => "Basic #{Base64.strict_encode64(authorization_string)}"
      },
      :body => URI.encode_www_form(body)
    )

    self.handle_token_result(result)
  end

  def self.handle_token_result(result)
    data = JSON.parse(result.body)
    return false if (data['error'])

    token = data['access_token']
    expires_at = Time.now + data['expires_in'].seconds
    refresh_at = expires_at.to_time - 2.hours

    Jobs.enqueue_at(refresh_at, :refresh_custom_wizard_access_token)

    CustomWizard::Authorization.set_access_token(
      token: token,
      expires_at: expires_at,
      refresh_at: refresh_at
    )

    CustomWizard::Authorization.set_refresh_token(data['refresh_token'])
  end

  def self.authorized
    CustomWizard::Authorization.access_token[:token] &&
    CustomWizard::Authorization.access_token[:expires_at].to_datetime > Time.now
  end
end
