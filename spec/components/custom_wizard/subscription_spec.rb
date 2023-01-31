# frozen_string_literal: true

describe CustomWizard::Subscription do
  def undefine_client_classes
    Object.send(:remove_const, :SubscriptionClient) if Object.constants.include?(:SubscriptionClient)
    Object.send(:remove_const, :SubscriptionClientSubscription) if Object.constants.include?(:SubscriptionClientSubscription)
  end

  def define_client_classes
    load File.expand_path("#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/subscription_client.rb", __FILE__)
  end

  def stub_client_methods
    [:active, :where, :order, :first].each do |method|
      SubscriptionClientSubscription.stubs(method)
        .returns(SubscriptionClientSubscription)
    end
    SubscriptionClientSubscription.stubs(:product_id).returns(SecureRandom.hex(8))
  end

  after do
    undefine_client_classes
  end

  it "detects the subscription client" do
    expect(described_class.client_installed?).to eq(false)
  end

  context "without a subscription client" do
    it "is not subscribed" do
      expect(described_class.subscribed?).to eq(false)
    end

    it "has none type" do
      subscription = described_class.new
      expect(subscription.type).to eq(:none)
    end

    it "non subscriber features are included" do
      expect(described_class.includes?(:wizard, :after_signup, true)).to eq(true)
    end

    it "ubscriber features are not included" do
      expect(described_class.includes?(:wizard, :permitted, {})).to eq(false)
    end
  end

  context "with subscription client" do
    before do
      define_client_classes
      stub_client_methods
    end

    it "detects the subscription client" do
      expect(described_class.client_installed?).to eq(true)
    end

    context "without a subscription" do
      it "has none type" do
        expect(described_class.type).to eq(:none)
      end

      it "non subscriber features are included" do
        expect(described_class.includes?(:wizard, :after_signup, true)).to eq(true)
      end

      it "subscriber features are not included" do
        expect(described_class.includes?(:wizard, :permitted, {})).to eq(false)
      end
    end

    context "with standard subscription" do
      before do
        SubscriptionClientSubscription.stubs(:product_id).returns(CustomWizard::Subscription::STANDARD_PRODUCT_ID)
      end

      it "detects standard type" do
        expect(described_class.type).to eq(:standard)
      end

      it "standard features are included" do
        expect(described_class.includes?(:wizard, :type, 'send_message')).to eq(true)
      end

      it "business features are not included" do
        expect(described_class.includes?(:action, :type, 'create_category')).to eq(false)
      end
    end

    context "with business subscription" do
      before do
        SubscriptionClientSubscription.stubs(:product_id).returns(CustomWizard::Subscription::BUSINESS_PRODUCT_ID)
      end

      it "detects business type" do
        expect(described_class.type).to eq(:business)
      end

      it "business features are included" do
        expect(described_class.includes?(:action, :type, 'create_category')).to eq(true)
      end
    end

    context "with community subscription" do
      before do
        SubscriptionClientSubscription.stubs(:product_id).returns(CustomWizard::Subscription::COMMUNITY_PRODUCT_ID)
      end

      it "detects community type" do
        expect(described_class.type).to eq(:community)
      end

      it "community features are included" do
        expect(described_class.includes?(:action, :type, 'create_category')).to eq(true)
      end
    end
  end
end
