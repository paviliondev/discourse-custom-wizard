class CustomWizard::Builder
  def initialize(user, wizard_id)
    @wizard = Wizard.new(user)
    @template = PluginStore.get('custom_wizard', wizard_id)
  end

  def build
    @template.each do |s|
      @wizard.append_step(s.title) do |step|

        step.banner = s.banner if s.banner

        s.fields.each do |f|
          field = step.add_field(id: f.id,
                                 type: f.type,
                                 required: f.required,
                                 value: f.value)

          if f.type == 'dropdown'
            f.choices.each do |c|
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
