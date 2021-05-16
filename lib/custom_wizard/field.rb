# frozen_string_literal: true

class CustomWizard::Field
  include ActiveModel::SerializerSupport

  def self.attributes
  %i{
    raw
    id
    index
    type
    step
    required
    value
    description
    image
    key
    validations
    min_length
    max_length
    char_counter
    file_types
    format
    limit
    property
    content
  }
  end

  def self.accessible_attributes
    %i{
      index
      step
    }
  end

  def self.excluded_attributes
    %i{
      label
    }
  end

  attr_reader *(attributes - accessible_attributes - excluded_attributes)
  attr_accessor *accessible_attributes

  def initialize(attrs)
    attrs.each do |k, v|
      if self.singleton_class.attributes.include?(k.to_sym)
        instance_variable_set("@#{k}", v)
      end
    end

    @raw = attrs || {}
    @required = !!attrs[:required]
    @value = attrs[:value] || default_value
  end

  def label
    @label ||= PrettyText.cook(@raw[:label])
  end

  def default_value
    if @type == 'checkbox'
      false
    end
  end

  def self.types
    @types ||= {
      text: {
        min_length: nil,
        max_length: nil,
        prefill: nil,
        char_counter: nil,
        validations: nil
      },
      textarea: {
        min_length: nil,
        max_length: nil,
        prefill: nil,
        char_counter: nil
      },
      composer: {
        min_length: nil,
        max_length: nil,
        char_counter: nil
      },
      text_only: {},
      date: {
        format: "YYYY-MM-DD"
      },
      time: {
        format: "HH:mm"
      },
      date_time: {
        format: ""
      },
      number: {},
      checkbox: {},
      url: {
        min_length: nil
      },
      upload: {
        file_types: '.jpg,.jpeg,.png'
      },
      dropdown: {
        prefill: nil,
        content: nil
      },
      tag: {
        limit: nil,
        prefill: nil,
        content: nil
      },
      category: {
        limit: 1,
        property: 'id',
        prefill: nil,
        content: nil
      },
      group: {
        prefill: nil,
        content: nil
      },
      user_selector: {}
    }
  end

  def self.require_assets
    @require_assets ||= {}
  end

  def self.register(type, plugin = nil, asset_paths = [], opts = {})
    if type
      types[type.to_sym] ||= {}
      types[type.to_sym] = opts[:type_opts] if opts[:type_opts].present?
    end

    if plugin && asset_paths
      require_assets[plugin] = asset_paths
    end
  end
end
