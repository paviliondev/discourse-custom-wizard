# frozen_string_literal: true

module ::CustomWizard
  module LiquidFilter
    module FirstNonEmpty
      def first_non_empty(*multiple)
        multiple.find { |var| var.present? }
      end
    end
  end
end
