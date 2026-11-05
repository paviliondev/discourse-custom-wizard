# frozen_string_literal: true

describe "Wizard steps" do
  fab!(:user)

  let(:tall_description) { (1..40).map { |i| "Paragraph #{i}" }.join("\n\n") }

  before do
    enable_subscription("standard")
    CustomWizard::Template.save(
      {
        id: "tall_wizard",
        name: "Tall wizard",
        steps: [
          {
            id: "step_1",
            raw_description: tall_description,
            fields: [{ id: "step_1_field_1", type: "text", label: "First" }],
          },
          {
            id: "step_2",
            raw_description: tall_description,
            fields: [{ id: "step_2_field_1", type: "composer", label: "Second" }],
          },
        ],
      }.as_json,
      skip_jobs: true,
    )
    sign_in(user)
  end

  it "shows the next step from the top when its composer is focused" do
    visit("/w/tall-wizard")
    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    find(".wizard-btn.next").click

    expect(page).to have_css(".wizard-step.step_2 .d-editor-input:focus")
    expect(page.evaluate_script("window.scrollY")).to eq(0)
  end
end
