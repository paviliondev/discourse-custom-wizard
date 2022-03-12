# frozen_string_literal: true

describe CustomWizard::RealtimeValidation do
  validation_names = CustomWizard::RealtimeValidation.types.keys

  validation_names.each do |name|
    klass_str = "CustomWizard::RealtimeValidation::#{name.to_s.camelize}"

    it "ensure class for validation: #{name} exists" do
      expect(klass_str.safe_constantize).not_to be_nil
    end

    it "#{klass_str} has a perform() method" do
      expect(klass_str.safe_constantize.instance_methods).to include(:perform)
    end
  end
end
