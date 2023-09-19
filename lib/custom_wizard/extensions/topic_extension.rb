# frozen_string_literal: true

DiscourseEvent.on(:before_create_topic) do |topic_params, user|
  category = topic_params.category
  if category&.custom_fields&.[]('create_topic_wizard').present?
    raise Discourse::InvalidParameters.new(
            I18n.t('wizard.error_messages.wizard_replacing_composer')
          )
  end
end
