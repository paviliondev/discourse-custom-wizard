# frozen_string_literal: true
UserHistory.actions[:custom_wizard_step] = 1000

class CustomWizard::UserHistory
  def self.where(actor_id: nil, action: nil, context: nil, subject: nil)
    ::UserHistory.where(where_opts(actor_id, action, context, subject))
  end

  def self.create(actor_id: nil, action: nil, context: nil, subject: nil)
    ::UserHistory.create(create_opts(actor_id, action, context, subject))
  end

  def self.create!(actor_id: nil, action: nil, context: nil, subject: nil)
    ::UserHistory.create!(create_opts(actor_id, action, context, subject))
  end

  def self.actions
    @actions ||= Enum.new(step: UserHistory.actions[:custom_wizard_step])
  end

  def self.where_opts(actor_id, action, context, subject)
    opts = { context: context }
    opts[:action] = action if action
    opts[:subject] = subject if subject
    add_actor(opts, actor_id)
  end

  def self.create_opts(actor_id, action, context, subject)
    opts = { action: action, context: context }
    opts[:subject] = subject if subject
    add_actor(opts, actor_id)
  end

  def self.add_actor(opts, actor_id)
    acting_user_id = actor_id

    if actor_id.is_a?(String) && actor_id.include?(CustomWizard::Wizard::GUEST_ID_PREFIX)
      opts[:acting_user_id] = Discourse.system_user.id
      opts[:details] = actor_id
    else
      opts[:acting_user_id] = actor_id
    end

    opts
  end
end
