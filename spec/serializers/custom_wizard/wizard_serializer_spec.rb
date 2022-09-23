# frozen_string_literal: true

describe CustomWizard::WizardSerializer do
  fab!(:user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }
  let(:template) { get_wizard_fixture("wizard") }
  let(:similar_topics_validation) { get_wizard_fixture("field/validation/similar_topics") }
  let(:advanced_fields) { get_wizard_fixture("field/advanced_types") }

  before do
    CustomWizard::Template.save(template, skip_jobs: true)
    @template = CustomWizard::Template.find('super_mega_fun_wizard')
  end

  it 'should return the wizard attributes' do
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:wizard][:id]).to eq("super_mega_fun_wizard")
    expect(json[:wizard][:name]).to eq("Super Mega Fun Wizard")
    expect(json[:wizard][:background]).to eq("#333333")
    expect(json[:wizard][:required]).to eq(false)
  end

  it 'should return the wizard steps' do
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:wizard][:steps].length).to eq(3)
  end

  it "should return the wizard user attributes" do
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(
      json[:wizard][:user]
    ).to eq(BasicUserSerializer.new(user, root: false).as_json)
  end
end
