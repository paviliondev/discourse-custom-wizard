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

  def title
    I18n.t("#{i18n_key}.title", default: object.title, base_url: Discourse.base_url)
  end

  def include_title?
    title.present?
  end

  def description
    I18n.t("#{i18n_key}.description", default: object.description, base_url: Discourse.base_url)
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

  protected

  def i18n_key
    @i18n_key ||= "#{object.wizard.id}.#{object.id}".underscore
  end
end
