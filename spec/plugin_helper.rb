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

def undefine_client_classes
  Object.send(:remove_const, :SubscriptionClient) if Object.constants.include?(:SubscriptionClient)
  Object.send(:remove_const, :SubscriptionClientSubscription) if Object.constants.include?(:SubscriptionClientSubscription)
end

def define_client_classes
  load File.expand_path("#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/subscription_client.rb", __FILE__)
end
