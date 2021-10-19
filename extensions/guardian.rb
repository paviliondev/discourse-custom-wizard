# frozen_string_literal: true
module CustomWizardGuardian
  def can_see_topic?(topic, hide_deleted = true)
    wizard_user_can_create_topic_on_category?(topic) || super
  end

  def can_edit_topic?(topic)
    wizard_user_can_create_topic_on_category?(topic) || super
  end

  def can_create_post?(parent)
    result = parent.present? ? wizard_user_can_create_topic_on_category?(parent) : false 
    result || super
  end

  private

  def wizard_user_can_create_topic_on_category?(topic)
    wizard = creating_wizard(topic)
    (wizard.present? && wizard.permitted? && wizard_can_create_topic_on_category?(wizard, topic))
  end

  def creating_wizard(topic)
    wizard_id = topic.wizard_created.presence
    wizard = CustomWizard::Builder.new(wizard_id, @user).build if wizard_id
    return wizard.presence
  end

  def wizard_can_create_topic_on_category?(wizard, topic)
    return false unless topic.category.present?

    wizard_actions = wizard.actions
    return false if wizard_actions.empty?

    create_topic_actions = wizard_actions.select do |action|
      action['type'] === 'create_topic'
    end

    submission_data = begin
      submissions = CustomWizard::Submission.list(wizard)
      submissions.find { |sub| sub.id == topic.wizard_submission }&.fields_and_meta
    end

    categories = wizard_actions.map do |action|
      category = CustomWizard::Mapper.new(
        inputs: action['category'],
        data: submission_data,
        user: @user
      ).perform

      category
    end

    categories.flatten!

    return true if categories.include?(topic.category.id)
    false
  end
end
