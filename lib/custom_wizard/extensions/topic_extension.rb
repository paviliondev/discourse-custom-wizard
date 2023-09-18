# frozen_string_literal: true

module CustomWizardTopicExtension
  extend ActiveSupport::Concern

  included { before_validation :check_wizard_replacement, on: :create }

  def check_wizard_replacement
    if wizard_replacing_composer?(self.category_id)
      self.errors.add(
        :base,
        I18n.t('wizard.error_messages.wizard_replacing_composer')
      )
    end
  end

  def wizard_replacing_composer?(category_id)
    return false unless category_id

    category = Category.find(category_id)
    category.custom_fields['create_topic_wizard'].present?
  end
end
