class CustomWizard::Template

  attr_reader :id,
              :name,
              :background,
              :save_submissions,
              :multiple_submissions,
              :prompt_completion,
              :restart_on_revisit,
              :after_signup,
              :after_time,
              :after_time_scheduled,
              :required,
              :theme_id,
              :permitted,
              :steps,
              :actions

  def initialize(data)
    data = data.is_a?(String) ? ::JSON.parse(data) : data

    return nil if data.blank?

    @id = data['id']
    @name = data['name']
    @background = data['background']
    @save_submissions = data['save_submissions'] || false
    @multiple_submissions = data['multiple_submissions'] || false
    @prompt_completion = data['prompt_completion'] || false
    @restart_on_revisit = data['restart_on_revisit'] || false
    @after_signup = data['after_signup']
    @after_time = data['after_time']
    @after_time_scheduled = data['after_time_scheduled']
    @required = data['required'] || false
    @theme_id = data['theme_id']
    @permitted = data['permitted'] || nil

    if data['theme']
      theme = Theme.find_by(name: data['theme'])
      @theme_id = theme.id if theme
    end
    
    @steps = data['steps']
    @actions = data['actions']
  end
end
