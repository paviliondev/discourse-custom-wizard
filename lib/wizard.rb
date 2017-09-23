class CustomWizard::Wizard

  attr_reader :name, :steps

  def initialize(data)
    parsed = ::JSON.parse(data)
    @name = parsed['name']
    @steps = JSON.parse(parsed['steps'])
  end
end
