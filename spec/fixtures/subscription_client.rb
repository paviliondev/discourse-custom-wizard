# frozen_string_literal: true

module SubscriptionClient
  def self.find_subscriptions(resource_name)
  end
end

class SubscriptionClientSupplier
  attr_reader :product_slugs

  def initialize(product_slugs)
    @product_slugs = product_slugs
  end
end

class SubscriptionClientResource
end

class SubscriptionClientSubscription
  attr_reader :product_id

  def initialize(product_id)
    @product_id = product_id
  end
end

module SubscriptionClient
  class Subscriptions
    class Result
      attr_accessor :supplier,
                    :resource,
                    :subscriptions,
                    :products

      def any?
        supplier.present? && resource.present? && subscriptions.present? && products.present?
      end
    end
  end
end
