# frozen_string_literal: true

describe CustomWizard::Subscription do
  let(:guests_permitted) { get_wizard_fixture("wizard/guests_permitted") }
  let!(:business_product_id) { SecureRandom.hex(8) }
  let!(:standard_product_id) { SecureRandom.hex(8) }
  let!(:community_product_id) { SecureRandom.hex(8) }
  let!(:product_slugs) {
    {
      "#{business_product_id}" => "business",
      "#{standard_product_id}" => "standard",
      "#{community_product_id}" => "community"
    }
  }

  def undefine_client_classes
    Object.send(:remove_const, :SubscriptionClient) if Object.constants.include?(:SubscriptionClient)
    Object.send(:remove_const, :SubscriptionClientSubscription) if Object.constants.include?(:SubscriptionClientSubscription)
  end

  def define_client_classes
    load File.expand_path("#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/subscription_client.rb", __FILE__)
  end

  after do
    undefine_client_classes
  end

  it "detects the subscription client" do
    undefine_client_classes
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

    it "subscriber features are not included" do
      expect(described_class.includes?(:wizard, :permitted, {})).to eq(false)
    end
  end

  context "with subscription client" do
    before do
      define_client_classes
    end

    it "detects the subscription client" do
      expect(described_class.client_installed?).to eq(true)
    end

    context "without a subscription" do
      before do
        SubscriptionClient.stubs(:find_subscriptions).returns(nil)
      end

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

    context "with subscriptions" do
      def get_subscription_result(product_id)
        result = SubscriptionClient::Subscriptions::Result.new
        result.supplier = SubscriptionClientSupplier.new(product_slugs)
        result.resource = SubscriptionClientResource.new
        result.subscriptions = [SubscriptionClientSubscription.new(product_id)]
        result.products = product_slugs
        result
      end
      let!(:business_subscription_result) { get_subscription_result(business_product_id) }
      let!(:standard_subscription_result) { get_subscription_result(standard_product_id) }
      let!(:community_subscription_result) { get_subscription_result(community_product_id) }

      it "handles mapped values" do
        SubscriptionClient.stubs(:find_subscriptions).returns(standard_subscription_result)
        expect(described_class.includes?(:wizard, :permitted, guests_permitted["permitted"])).to eq(true)

        SubscriptionClient.stubs(:find_subscriptions).returns(community_subscription_result)
        expect(described_class.includes?(:wizard, :permitted, guests_permitted["permitted"])).to eq(false)
      end

      context "with a standard subscription" do
        before do
          SubscriptionClient.stubs(:find_subscriptions).returns(standard_subscription_result)
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

      context "with a business subscription" do
        before do
          SubscriptionClient.stubs(:find_subscriptions).returns(business_subscription_result)
        end

        it "detects business type" do
          expect(described_class.type).to eq(:business)
        end

        it "business features are included" do
          expect(described_class.includes?(:action, :type, 'create_category')).to eq(true)
        end
      end

      context "with a community subscription" do
        before do
          SubscriptionClient.stubs(:find_subscriptions).returns(community_subscription_result)
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
end
