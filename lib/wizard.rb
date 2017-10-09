class CustomWizard::Wizard

  attr_reader :id, :name, :steps, :background, :save_submissions, :custom

  def initialize(data)
    data = data.is_a?(String) ? ::JSON.parse(data) : data
    @id = data['id']
    @name = data['name']
    @background = data['background']
    @save_submissions = data['save_submissions']
    @steps = data['steps']
    @custom = true
  end
end
