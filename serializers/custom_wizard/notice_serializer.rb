# frozen_string_literal: true

class CustomWizard::NoticeSerializer < ApplicationSerializer
  attributes :id,
             :message,
             :type,
             :created_at,
             :expired_at,
             :updated_at,
             :dismissed_at,
             :retrieved_at,
             :dismissable

  def dismissable
    object.dismissable?
  end

  def type
    CustomWizard::Notice.types.key(object.type)
  end

  def messsage
    PrettyText.cook(object.message)
  end
end
