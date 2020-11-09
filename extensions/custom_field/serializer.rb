module CustomWizardCustomFieldSerializer
  def attributes(*args)
    hash = super
    @cw_klass = get_cw_class
    
    if cw_fields.any?
      cw_fields.each do |field|
        if @cw_klass == "topic_view"
          hash[field.name.to_sym] = object.topic.custom_fields["#{field.name}"]
        else
          hash[field.name.to_sym] = object.custom_fields["#{field.name}"]
        end
      end
    end
    
    hash
  end
  
  private

  def cw_fields
    CustomWizard::CustomField.list_by(:serializers, @cw_klass)
  end
  
  def get_cw_class
    self.class.ancestors.map do |klass|
      klass.to_s.underscore.gsub("_serializer", "")
    end.select do |klass|
      CustomWizard::CustomField.serializers.include?(klass)
    end.first
  end
end