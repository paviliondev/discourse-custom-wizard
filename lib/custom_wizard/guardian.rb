# frozen_string_literal: true
class CustomWizard::Guardian
  def initialize(user)
    @user = user
  end

  def can_edit_topic?(topic)
    creating_wizard = topic.wizard_created.presence
    return false unless creating_wizard

    wizard_builder = CustomWizard::Builder.new(creating_wizard, @user)
    wizard = wizard_builder.build
    wizard_actions = wizard.actions
    return false if wizard_actions.empty?

    create_topic_action = wizard_actions.find do |action|
      action['type'] === 'create_topic'
    end

    return wizard_can_create_topic_on_category?(action, topic)
  end

  private

  def wizard_can_create_topic_on_category?(action, topic)
    return false unless topic.category.present?

    category = CustomWizard::Mapper.new(
      inputs: action['category'],
      data: 
    )
  end
end
