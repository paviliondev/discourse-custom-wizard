class CustomWizard::Wizard

  attr_reader :name, :steps

  def initialize(data)
    parsed = ::JSON.parse(data)
    @id = parsed['id']
    @name = parsed['name']
    @steps = parsed['steps']
  end
end
