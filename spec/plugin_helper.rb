# frozen_string_literal: true

def get_wizard_fixture(path)
  JSON.parse(
    File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/#{path}.json"
    ).read
  ).with_indifferent_access
end

def enable_subscription(type)
  CustomWizard::Subscription.stubs("#{type}?".to_sym).returns(true)
  CustomWizard::Subscription.any_instance.stubs("#{type}?".to_sym).returns(true)
end

def disable_subscriptions
  %w[
    standard
    business
    community
  ].each do |type|
    CustomWizard::Subscription.stubs("#{type}?".to_sym).returns(false)
    CustomWizard::Subscription.any_instance.stubs("#{type}?".to_sym).returns(false)
  end
end
