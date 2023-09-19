# frozen_string_literal: true

describe Topic, type: :model do
  fab!(:category_with_wizard) do
    Fabricate(:category, custom_fields: { create_topic_wizard: 'true' })
  end
  fab!(:category_without_wizard) { Fabricate(:category) }
  fab!(:user) { Fabricate(:user) }
  let(:valid_attrs) { Fabricate.attributes_for(:topic) }

  context 'with a create_topic_wizard custom field in the category' do
    it 'will not allow creating a topic directly' do
      expect do
        TopicCreator.create(
          user,
          Guardian.new(user),
          valid_attrs.merge(
            title: 'A valid and sufficiently long title for testing',
            category: category_with_wizard.id,
            raw: 'hello this is a test topic with category with custom fields'
          )
        )
      end.to raise_error(
        Discourse::InvalidParameters,
        'Category not allowed for topic creation.'
      )
    end
  end

  context 'without a create_topic_wizard custom field in the category' do
    it 'will allow creating a topic directly' do
      expect do
        TopicCreator.create(
          user,
          Guardian.new(user),
          valid_attrs.merge(
            category: category_without_wizard.id,
            title: 'Another valid and sufficiently long title for testing',
            raw: 'This is the body of a valid topic'
          )
        )
      end.not_to raise_error
    end
  end
end
