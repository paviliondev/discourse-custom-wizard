module CustomWizardFieldExtension
  attr_reader :raw,
              :label,
              :description,
              :image,
              :key,
              :min_length,
              :max_length,
              :file_types,
              :format,
              :limit,
              :property,
              :content,
              :number
              
  def initialize(attrs)
    super
    @raw = attrs || {}
    @description = attrs[:description]
    @image = attrs[:image]
    @key = attrs[:key]
    @min_length = attrs[:min_length]
    @max_length = attrs[:max_length]
    @file_types = attrs[:file_types]
    @format = attrs[:format]
    @limit = attrs[:limit]
    @property = attrs[:property]
    @content = attrs[:content]
    @number = attrs[:number]
  end

  def label
    @label ||= PrettyText.cook(@raw[:label])
  end
end