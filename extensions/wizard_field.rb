module CustomWizardFieldExtension
  attr_reader :label,
              :description,
              :image,
              :key,
              :min_length,
              :file_types,
              :limit,
              :property,
              :content
              
  def initialize(attrs)
    super
    @attrs = attrs || {}
    @description = attrs[:description]
    @image = attrs[:image]
    @key = attrs[:key]
    @min_length = attrs[:min_length]
    @file_types = attrs[:file_types]
    @limit = attrs[:limit]
    @property = attrs[:property]
    @content = attrs[:content]
  end

  def label
    @label ||= PrettyText.cook(@attrs[:label])
  end
end