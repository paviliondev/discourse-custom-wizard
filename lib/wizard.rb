class CustomWizard::Wizard

  attr_reader :id, :name, :steps, :custom

  def initialize(data)
    data = data.is_a?(String) ? ::JSON.parse(data) : data
    @id = data['id']
    @name = data['name']
    @steps = data['steps']
    @custom = true
  end
end
