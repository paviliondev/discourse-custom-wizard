class CustomWizard::Template

  attr_reader :id,
              :name,
              :steps,
              :background,
              :save_submissions,
              :multiple_submissions,
              :prompt_completion,
              :min_trust,
              :after_signup,
              :after_time,
              :after_time_scheduled,
              :required,
              :theme_key

  def initialize(data)
    data = data.is_a?(String) ? ::JSON.parse(data) : data
    @id = data['id']
    @name = data['name']
    @steps = data['steps']
    @background = data['background']
    @save_submissions = data['save_submissions'] || false
    @multiple_submissions = data['multiple_submissions'] || false
    @prompt_completion = data['prompt_completion'] || false
    @min_trust = data['min_trust'] || 0
    @after_signup = data['after_signup']
    @after_time = data['after_time']
    @after_time_scheduled = data['after_time_scheduled']
    @required = data['required'] || false
    @theme_key = data['theme_key']
  end
end
