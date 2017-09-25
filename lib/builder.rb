class CustomWizard::Builder
  def initialize(user, wizard_name)
    rows = PluginStoreRow.where(plugin_name: 'custom_wizards')
    return if !rows

    [*rows].each do |r|
      wizard = CustomWizard::Wizard.new(r.value)
      @template = wizard if wizard.name.dasherize.downcase == wizard_name
    end

    @wizard = Wizard.new(user)
  end

  def build
    @template.steps.each do |s|
      @wizard.append_step(s['title']) do |step|

        step.banner = s['banner'] if s['banner']

        s['fields'].each do |f|
          field = step.add_field(id: f['id'],
                                 type: f['type'],
                                 required: f['required'],
                                 value: f['value'])

          if f['type'] == 'dropdown'
            f['choices'].each do |c|
              field.add_choice(c)
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
