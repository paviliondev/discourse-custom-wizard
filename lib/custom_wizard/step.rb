# frozen_string_literal: true

class CustomWizard::Step
  include ActiveModel::SerializerSupport

  attr_reader :id,
              :updater

  attr_accessor :index,
                :title,
                :description,
                :key,
                :permitted,
                :permitted_message,
                :fields,
                :next,
                :previous,
                :banner,
                :disabled,
                :description_vars,
                :force_final,
                :final_step,
                :final_conditional_step,
                :wizard

  def initialize(id)
    @id = id
    @fields = []
  end

  def add_field(attrs)
    field = ::CustomWizard::Field.new(attrs)
    field.index = (@fields.size == 1 ? 0 : @fields.size) if field.index.nil?
    field.step = self
    @fields << field
    field
  end

  def has_fields?
    @fields.present?
  end

  def on_update(&block)
    @updater = block
  end

  def update_field_order!
    @fields.sort_by!(&:index)
  end

  def final?
    return true if force_final && final_conditional_step
    return true if final_step
    false
  end
end
