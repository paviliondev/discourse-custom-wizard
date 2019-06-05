require 'excon'
# require 'httplog'

class CustomWizard::APITestHarness

  def self.basic

    CustomWizard::Authorization.set_authentication_protocol("chargify", "basic_authentication")
    CustomWizard::Authorization.set_username("chargify", "W2iA5khmmRso3oySy1KUeJP17ilUuN6OZkgT8PPwk")
    CustomWizard::Authorization.set_password("chargify", "X")
    authentication_string = CustomWizard::Authorization.get_header_authorization_string("chargify")
    puts 'authentication string is ' + authentication_string
    response = Excon.get(
      "https://merefield-technology.chargify.com/subscriptions.json",
      :headers => {
        "Authorization" => "#{authentication_string}"
      }
    )
    JSON.parse(response.body)
  end

  def self.oauth_two

    CustomWizard::Authorization.set_authentication_protocol("google", "OAuth2_authentication")
    CustomWizard::Authorization.set_client_id("chargify", "W2iA5khmmRso3oySy1KUeJP17ilUuN6OZkgT8PPwk")
    CustomWizard::Authorization.set_client_secret("chargify", "X")

    puts curl
    authentication_string = CustomWizard::Authorization.get_header_authorization_string("chargify")
    puts 'authentication string is ' + authentication_string
    response = Excon.get(
      "https://merefield-technology.chargify.com/subscriptions.json",
      :headers => {
        "Authorization" => "#{authentication_string}"
      }
    )
    JSON.parse(response.body)
  end

end
