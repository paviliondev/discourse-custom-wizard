# frozen_string_literal: true

class CustomWizard::Field
  include ActiveModel::SerializerSupport

  attr_reader :raw,
              :id,
              :type,
              :required,
              :value,
              :label,
              :description,
              :image,
              :image_upload_id,
              :validations,
              :min_length,
              :max_length,
              :char_counter,
              :file_types,
              :format,
              :limit,
              :property,
              :content,
              :tag_groups,
              :preview_template,
              :placeholder

  attr_accessor :index,
                :step

  def initialize(attrs)
    @raw = attrs || {}
    @id = attrs[:id]
    @index = attrs[:index]
    @type = attrs[:type]
    @required = !!attrs[:required]
    @value = attrs[:value] || default_value
    @description = attrs[:description]
    @image = attrs[:image]
    @validations = attrs[:validations]
    @min_length = attrs[:min_length]
    @max_length = attrs[:max_length]
    @char_counter = attrs[:char_counter]
    @file_types = attrs[:file_types]
    @format = attrs[:format]
    @limit = attrs[:limit]
    @property = attrs[:property]
    @content = attrs[:content]
    @tag_groups = attrs[:tag_groups]
    @preview_template = attrs[:preview_template]
    @placeholder = attrs[:placeholder]
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
        validations: nil,
        placeholder: nil
      },
      textarea: {
        min_length: nil,
        max_length: nil,
        prefill: nil,
        char_counter: nil,
        placeholder: nil
      },
      composer: {
        min_length: nil,
        max_length: nil,
        char_counter: nil,
        placeholder: nil
      },
      text_only: {},
      composer_preview: {
        preview_template: nil,
      },
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
        content: nil,
        tag_groups: nil
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
    Rails.logger.warn("Custom Wizard field regisration no longer requires asset registration. Support will be removed in v2.1.0.")

    @require_assets ||= {}
  end

  def self.register(type, plugin = nil, opts = {}, legacy_opts = {})
    if opts.is_a?(Array)
      Rails.logger.warn("Custom Wizard field regisration no longer requires asset registration. Support will be removed in v2.1.0.")

      require_assets[plugin] = opts
      opts = legacy_opts
    end

    if type
      types[type.to_sym] ||= {}
      types[type.to_sym] = opts[:type_opts] if opts[:type_opts].present?
    end
  end
end
