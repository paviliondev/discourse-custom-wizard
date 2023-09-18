# frozen_string_literal: true

class DummyTopic < Topic
  include CustomWizardTopicExtension
end

describe DummyTopic, type: :model do
  fab!(:category_with_wizard) do
    Fabricate(:category, custom_fields: { create_topic_wizard: 'true' })
  end
  fab!(:category_without_wizard) { Fabricate(:category) }
  fab!(:user) { Fabricate(:user) }

  context 'when the category has a create_topic_wizard custom field' do
    it 'does not allow creating a topic directly' do
      topic = DummyTopic.new(user: user, category: category_with_wizard)
      topic.valid?
      expect(topic.errors[:base]).to include(
        I18n.t('wizard.error_messages.wizard_replacing_composer')
      )
    end
  end

  context 'when the category does not have a create_topic_wizard custom field' do
    it 'allows creating a topic directly' do
      topic =
        DummyTopic.new(
          user: user,
          category: category_without_wizard,
          title: 'A valid topic title'
        )
      is_valid = topic.valid?
      puts topic.errors.full_messages unless is_valid
      expect(is_valid).to be_truthy
    end
  end
end
