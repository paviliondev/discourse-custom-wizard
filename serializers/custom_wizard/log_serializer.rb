# frozen_string_literal: true

class CustomWizard::LogSerializer < ApplicationSerializer
  attributes :date,
             :action,
             :username,
             :message

  has_one :user, serializer: ::BasicUserSerializer, embed: :objects
end
