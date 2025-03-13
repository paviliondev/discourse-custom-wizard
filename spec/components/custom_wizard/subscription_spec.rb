# frozen_string_literal: true

describe CustomWizard::Subscription do
  let(:guests_permitted) { get_wizard_fixture("wizard/guests_permitted") }
  let!(:business_product_id) { SecureRandom.hex(8) }
  let!(:standard_product_id) { SecureRandom.hex(8) }
  let!(:community_product_id) { SecureRandom.hex(8) }
  let!(:product_slugs) do
    {
      "#{business_product_id}" => "business",
      "#{standard_product_id}" => "standard",
      "#{community_product_id}" => "community",
    }
  end

  context "with subscription client gem mocked out" do
    context "without a subscription" do
      before { DiscourseSubscriptionClient.stubs(:find_subscriptions).returns(nil) }

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
      def get_subscription_result(product_ids)
        result = DiscourseSubscriptionClient::Subscriptions::Result.new
        result.supplier = SubscriptionClientSupplier.new(products: product_slugs)
        result.resource = SubscriptionClientResource.new
        result.subscriptions =
          product_ids.map do |product_id|
            ::SubscriptionClientSubscription.new(product_id: product_id)
          end
        result.products = product_slugs
        result
      end
      let!(:business_subscription_result) { get_subscription_result([business_product_id]) }
      let!(:standard_subscription_result) { get_subscription_result([standard_product_id]) }
      let!(:community_subscription_result) { get_subscription_result([community_product_id]) }
      let!(:multiple_subscription_result) do
        get_subscription_result([community_product_id, business_product_id])
      end

      it "handles mapped values" do
        DiscourseSubscriptionClient.stubs(:find_subscriptions).returns(standard_subscription_result)
        expect(described_class.includes?(:wizard, :permitted, guests_permitted["permitted"])).to eq(
          true,
        )

        DiscourseSubscriptionClient.stubs(:find_subscriptions).returns(
          community_subscription_result,
        )
        expect(described_class.includes?(:wizard, :permitted, guests_permitted["permitted"])).to eq(
          false,
        )
      end

      context "with a standard subscription" do
        before do
          DiscourseSubscriptionClient.stubs(:find_subscriptions).returns(
            standard_subscription_result,
          )
        end

        it "detects standard type" do
          expect(described_class.type).to eq(:standard)
        end

        it "standard features are included" do
          expect(described_class.includes?(:wizard, :type, "send_message")).to eq(true)
        end

        it "business features are not included" do
          expect(described_class.includes?(:action, :type, "create_category")).to eq(false)
        end
      end

      context "with a business subscription" do
        before do
          DiscourseSubscriptionClient.stubs(:find_subscriptions).returns(
            business_subscription_result,
          )
        end

        it "detects business type" do
          expect(described_class.type).to eq(:business)
        end

        it "business features are included" do
          expect(described_class.includes?(:action, :type, "create_category")).to eq(true)
        end
      end

      context "with a community subscription" do
        before do
          DiscourseSubscriptionClient.stubs(:find_subscriptions).returns(
            community_subscription_result,
          )
        end

        it "detects community type" do
          expect(described_class.type).to eq(:community)
        end

        it "community features are included" do
          expect(described_class.includes?(:action, :type, "create_category")).to eq(true)
        end
      end

      context "with multiple subscriptions" do
        before do
          DiscourseSubscriptionClient.stubs(:find_subscriptions).returns(
            multiple_subscription_result,
          )
        end

        it "detects correct type in hierarchy" do
          expect(described_class.type).to eq(:business)
        end
      end
    end
  end

  context "with environment variable" do
    before { ENV["CUSTOM_WIZARD_PRODUCT_SLUG"] = "standard" }

    after { ENV["CUSTOM_WIZARD_PRODUCT_SLUG"] = nil }

    it "enables the relevant subscription" do
      expect(described_class.type).to eq(:standard)
    end

    context "with a subscription" do
      before { enable_subscription("business") }

      it "respects the subscription" do
        expect(described_class.type).to eq(:business)
      end
    end
  end

  context "with a site setting" do
    before { SiteSetting.wizard_subscription_product_key = "standard" }

    after { SiteSetting.wizard_subscription_product_key = nil }

    it "enables the relevant subscription" do
      expect(described_class.type).to eq(:standard)
    end

    context "with a subscription" do
      before { enable_subscription("business") }

      it "respects the subscription" do
        expect(described_class.type).to eq(:business)
      end
    end
  end
end
