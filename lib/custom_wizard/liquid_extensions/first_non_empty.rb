module ::CustomWizard
  module LiquidFilter
    module FirstNonEmpty
      def first_non_empty(*multiple)
        return multiple.find{ |var| var.present? }
      end
    end
  end
end
