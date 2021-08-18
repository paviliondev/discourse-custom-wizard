# frozen_string_literal: true

class CustomWizard::Pro
  attr_reader :authentication,
              :subscription

  def initialize
    @authentication = CustomWizard::ProAuthentication.new
    @subscription = CustomWizard::ProSubscription.new
  end

  def server
    "test.thepavilion.io"
  end

  def subscription_type
    "stripe"
  end

  def client_name
    "custom-wizard"
  end

  def authorized?
    @authentication.active?
  end

  def subscribed?
    @subscription.active?
  end

  def update_subscription
    if @authentication.active?
      response = Excon.get(
        "https://#{server}/subscription-server/user-subscriptions/#{subscription_type}/#{client_name}",
        headers: {
          "User-Api-Key" => @authentication.api_key
        }
      )

      if response.status == 200
        begin
          data = JSON.parse(response.body).deep_symbolize_keys
        rescue JSON::ParserError
          return false
        end

        return @subscription.update(data)        
      end
    end

    @subscription.destroy
    false
  end

  def destroy
    @authentication.destroy
  end

  def auth_request(user_id, request_id)
    keys = @authentication.generate_keys(user_id, request_id)

    params = {
      public_key: keys.public_key,
      nonce: keys.nonce,
      client_id: @authentication.client_id,
      auth_redirect: "#{Discourse.base_url}/admin/wizards/pro/authorize/callback",
      application_name: SiteSetting.title,
      scopes: "discourse-subscription-server:user_subscription"
    }

    uri = URI.parse("https://#{server}/user-api-key/new")
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def auth_response(request_id, payload)
    data = @authentication.decrypt_payload(request_id, payload)
    return unless data.is_a?(Hash) && data[:key] && data[:user_id]
    @authentication.update(data)
  end

  def self.update
    self.new.update
  end

  def self.destroy
    self.new.destroy
  end

  def self.generate_request
    self.new.generate_request
  end

  def self.handle_response
    self.new.handle_response
  end

  def self.subscribed?
    self.new.subscribed?
  end

  def self.namespace
    "custom_wizard_pro"
  end
end