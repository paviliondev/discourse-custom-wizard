# frozen_string_literal: true

def get_wizard_fixture(path)
  JSON.parse(
    File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/#{path}.json"
    ).read
  ).with_indifferent_access
end

def enable_subscription(type)
  stub_out_subscription_classes
  CustomWizard::Subscription.stubs("#{type}?".to_sym).returns(true)
  CustomWizard::Subscription.any_instance.stubs("#{type}?".to_sym).returns(true)
end

def disable_subscriptions
  stub_out_subscription_classes
  %w[
    standard
    business
    community
  ].each do |type|
    CustomWizard::Subscription.stubs("#{type}?".to_sym).returns(false)
    CustomWizard::Subscription.any_instance.stubs("#{type}?".to_sym).returns(false)
  end
end

def unstub_out_subscription_classes
  Object.send(:remove_const, :DiscourseSubscriptionClient) if Object.constants.include?(:DiscourseSubscriptionClient)
  Object.send(:remove_const, :SubscriptionClientSubscription) if Object.constants.include?(:SubscriptionClientSubscription)
end

def stub_out_subscription_classes
  load File.expand_path("#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/subscription_client.rb", __FILE__)
end
