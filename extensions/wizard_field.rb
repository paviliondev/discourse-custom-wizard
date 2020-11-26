module CustomWizardFieldExtension
  attr_reader :raw,
              :label,
              :description,
              :image,
              :key,
              :min_length,
              :file_types,
              :format,
              :limit,
              :property,
              :content
              
  def initialize(attrs)
    super
    @raw = attrs || {}
    @description = attrs[:description]
    @image = attrs[:image]
    @key = attrs[:key]
    @min_length = attrs[:min_length]
    @file_types = attrs[:file_types]
    @format = attrs[:format]
    @limit = attrs[:limit]
    @property = attrs[:property]
    @content = attrs[:content]
  end

  def label
    @label ||= PrettyText.cook(@raw[:label])
  end
end