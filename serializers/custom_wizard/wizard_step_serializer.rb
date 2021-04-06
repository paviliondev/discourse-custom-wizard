# frozen_string_literal: true

class CustomWizard::StepSerializer < ::ApplicationSerializer

  attributes :id,
             :index,
             :next,
             :previous,
             :description,
             :title,
             :banner,
             :permitted,
             :permitted_message,
             :final

  has_many :fields, serializer: ::CustomWizard::FieldSerializer, embed: :objects

  def id
    object.id
  end

  def index
    object.index
  end

  def next
    object.next.id if object.next.present?
  end

  def include_next?
    object.next.present?
  end

  def previous
    object.previous.id if object.previous.present?
  end

  def include_previous?
    object.previous.present?
  end

  def i18n_key
    @i18n_key ||= "wizard.step.#{object.id}".underscore
  end

  def title
    return PrettyText.cook(object.title) if object.title
    PrettyText.cook(I18n.t("#{object.key || i18n_key}.title", default: ''))
  end

  def include_title?
    title.present?
  end

  def description
    return object.description if object.description
    PrettyText.cook(I18n.t("#{object.key || i18n_key}.description", default: '', base_url: Discourse.base_url))
  end

  def include_description?
    description.present?
  end

  def banner
    object.banner
  end

  def include_banner?
    object.banner.present?
  end

  def permitted
    object.permitted
  end

  def permitted_message
    object.permitted_message
  end

  def final
    object.final?
  end
end
