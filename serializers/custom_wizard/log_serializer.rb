# frozen_string_literal: true
class CustomWizard::LogSerializer < ApplicationSerializer
  attributes :date, :wizard, :action, :user, :message
end
