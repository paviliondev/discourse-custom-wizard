# frozen_string_literal: true

module DiscourseSubscriptionClient
  def self.find_subscriptions(resource_name)
  end
end

SubscriptionClientSupplier =
  Class.new Object do
    attr_reader :product_slugs

    def initialize(product_slugs)
      @product_slugs = product_slugs
    end
  end

SubscriptionClientResource =
  Class.new Object do
  end

SubscriptionClientSubscription =
  Class.new Object do
    attr_reader :product_id

    def initialize(product_id)
      @product_id = product_id
    end
  end

module DiscourseSubscriptionClient
  class Subscriptions
    class Result
      attr_accessor :supplier, :resource, :subscriptions, :products

      def any?
        supplier.present? && resource.present? && subscriptions.present? && products.present?
      end
    end
  end
end
