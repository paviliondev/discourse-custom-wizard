# frozen_string_literal: true

class CustomWizard::NoticeSerializer < ApplicationSerializer
  attributes :id,
             :title,
             :message,
             :type,
             :archetype,
             :created_at,
             :expired_at,
             :updated_at,
             :dismissed_at,
             :retrieved_at,
             :hidden_at,
             :dismissable,
             :can_hide

  def dismissable
    object.dismissable?
  end

  def can_hide
    object.can_hide?
  end

  def type
    CustomWizard::Notice.types.key(object.type)
  end

  def messsage
    PrettyText.cook(object.message)
  end
end
