# frozen_string_literal: true

describe CustomWizard::BasicWizardSerializer do
  fab!(:user) { Fabricate(:user) }
  let(:template) { get_wizard_fixture("wizard") }

  it 'should return basic wizard attributes' do
    CustomWizard::Template.save(template, skip_jobs: true)
    json = CustomWizard::BasicWizardSerializer.new(
      CustomWizard::Builder.new("super_mega_fun_wizard", user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:basic_wizard][:id]).to eq("super_mega_fun_wizard")
    expect(json[:basic_wizard][:name]).to eq("Super Mega Fun Wizard")
  end
end
