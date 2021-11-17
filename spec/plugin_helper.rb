# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-custom-wizard"
    track_files "plugins/discourse-custom-wizard/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb|api|gems)/ }
    SimpleCov.minimum_coverage 80
  end
end

require 'oj'
Oj.default_options = Oj.default_options.merge(cache_str: -1)

require 'rails_helper'
require 'webmock/rspec'

def get_wizard_fixture(path)
  JSON.parse(
    File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/#{path}.json"
    ).read
  ).with_indifferent_access
end

def authenticate_subscription
  CustomWizard::Subscription::Authentication.any_instance.stubs(:active?).returns(true)
end

def enable_subscription(type)
  # CustomWizard::Subscription.new
  CustomWizard::Subscription.any_instance.stubs(:subscribed?).returns(true)
  CustomWizard::Subscription.any_instance.stubs(:type).returns(type)
end

def disable_subscription
  CustomWizard::Subscription.any_instance.stubs(:subscribed?).returns(false)
end

def valid_subscription
  {
    product_id: "prod_CBTNpi3fqWWkq0",
    price_id: "price_id",
    price_nickname: "business"
  }
end

def invalid_subscription
  {
    product_id: "prod_CBTNpi3fqWWkq0",
    price_id: "price_id"
  }
end

def stub_subscription_request(status, subscription)
  authenticate_subscription
  sub = CustomWizard::Subscription.new
  stub_request(:get, "https://#{sub.server}/subscription-server/user-subscriptions/#{sub.subscription_type}/#{sub.client_name}").to_return(status: status, body: { subscriptions: [subscription] }.to_json)
end
