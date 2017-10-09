class CustomWizard::Builder

  def initialize(user, wizard_id)
    data = PluginStore.get('custom_wizard', wizard_id)
    @custom_wizard = CustomWizard::Wizard.new(data)
    @wizard = Wizard.new(user)
    @wizard.id = wizard_id
    @wizard.save_submissions = data['save_submissions']
    @wizard.background = data["background"]
  end

  def self.sorted_handlers
    @sorted_handlers ||= []
  end

  def self.step_handlers
    sorted_handlers.map { |h| { wizard_id: h[:wizard_id], block: h[:block] } }
  end

  def self.add_step_handler(priority = 0, wizard_id, &block)
    sorted_handlers << { priority: priority, wizard_id: wizard_id, block: block }
    @sorted_handlers.sort_by! { |h| -h[:priority] }
  end

  def build
    @custom_wizard.steps.each do |s|
      @wizard.append_step(s['id']) do |step|
        step.title = s['title'] if s['title']
        step.description = s['description'] if s['description']
        step.banner = s['banner'] if s['banner']
        step.translation_key = s['translation_key'] if s['translation_key']

        s['fields'].each do |f|
          params = {
            id: f['id'],
            type: f['type'],
            required: f['required']
          }

          params[:label] = f['label'] if f['label']
          params[:description] = f['description'] if f['description']
          params[:translation_key] = f['translation_key'] if f['translation_key']

          field = step.add_field(params)

          if f['type'] == 'dropdown'
            f['choices'].each do |c|
              field.add_choice(c['id'], label: c['label'])
            end
          end
        end

        step.on_update do |updater|

          @updater = updater
          input = updater.fields
          user = @wizard.user

          if @wizard.save_submissions && input
            store_key = @wizard.id
            submissions = Array.wrap(PluginStore.get("custom_wizard_submissions", store_key))
            submission = {}

            if submissions.last && submissions.last['completed'] === false
              submission = submissions.last
              submissions.pop(1)
            end

            submission['user_id'] = @wizard.user.id
            submission['completed'] = updater.step.next.nil?

            input.each do |key, value|
              submission[key] = value
            end

            submissions.push(submission)

            PluginStore.set('custom_wizard_submissions', store_key, submissions)
          end

          if s['actions'] && s['actions'].length
            s['actions'].each do |a|
              if a['type'] === 'create_topic'
                creator = PostCreator.new(user,
                                title: input[a['title']],
                                raw: input[a['post']],
                                category: a['category_id'],
                                skip_validations: true)

                post = creator.create
                if creator.errors.present?
                  raise StandardError, creator.errors.full_messages.join(" ")
                end

                updater.result = { topic_id: post.topic.id }
              end

              if a['type'] === 'send_message'
                creator = PostCreator.new(user,
                                title: input[a['title']],
                                raw: input[a['post']],
                                archetype: Archetype.private_message,
                                target_usernames: a['username'])

                post = creator.create

                if creator.errors.present?
                  raise StandardError, creator.errors.full_messages.join(" ")
                end

                updater.result = { topic_id: post.topic.id }
              end
            end
          end

          CustomWizard::Builder.step_handlers.each do |handler|
            if handler[:wizard_id] == @wizard.id
              handler[:block].call(self)
            end
          end
        end
      end
    end

    @wizard
  end
end
