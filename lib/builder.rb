class CustomWizard::Builder
  def initialize(user, wizard_id)
    data = PluginStore.get('custom_wizard', wizard_id)
    @custom_wizard = CustomWizard::Wizard.new(data)
    @wizard = Wizard.new(user)
    @wizard.id = wizard_id
  end

  def build
    @custom_wizard.steps.each do |s|
      @wizard.append_step(s['id']) do |step|
        step.title = s['title'] if s['title']
        step.banner = s['banner'] if s['banner']

        s['fields'].each do |f|
          field = step.add_field(id: f['id'],
                                 type: f['type'],
                                 label: f['label'],
                                 description: f['description'],
                                 required: f['required'])

          if f['type'] == 'dropdown'
            f['choices'].each do |c|
              field.add_choice(c['id'], label: c['label'])
            end
          end
        end

        step.on_update do |updater|
          puts "UPDATER: #{updater}"
          ## do stuff
        end
      end
    end

    @wizard
  end
end
