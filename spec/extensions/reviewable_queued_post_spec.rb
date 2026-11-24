# frozen_string_literal: true

describe CustomWizardReviewableQueuedPost, type: :request do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:moderator)
  fab!(:category)

  let(:wizard_template) { get_wizard_fixture("wizard") }
  let(:wizard_path) { "/w/super-mega-fun-wizard" }

  before do
    SiteSetting.custom_wizard_reopen_on_revise = true
    category.update!(topic_posting_review_mode: :everyone)
    wizard_template["multiple_submissions"] = true
    wizard_template["actions"][0]["visible"][0]["output"] = "false"
    wizard_template["actions"][0]["category"] = [
      {
        type: "assignment",
        output: category.id.to_s,
        output_type: "text",
        output_connector: "set",
      },
    ]
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    sign_in(user)
  end

  def submit_step(step_id, fields = {})
    put "#{wizard_path}/steps/#{step_id}.json", params: { fields: fields }
    expect(response.status).to eq(200)
  end

  def complete_wizard(title: "Topic Title", body: "topic body")
    submit_step("step_1", step_1_field_1: title, step_1_field_2: body)
    submit_step("step_2")
    submit_step("step_3")
  end

  def queued_topic
    ReviewableQueuedPost.find_by(target_created_by: user, status: :pending)
  end

  def revise(reviewable)
    reviewable.perform(
      moderator,
      :revise_and_reject_post,
      revise_reason: "Needs more detail",
      revise_feedback: "Please describe the outcome.",
    )
  end

  def wizard
    CustomWizard::Builder.new("super_mega_fun_wizard", user).build
  end

  def field_value(field_id)
    wizard.steps.flat_map(&:fields).find { |field| field.id == field_id }.value
  end

  def last_message
    Topic.private_messages_for_user(user).order(:created_at).last&.first_post&.raw
  end

  def expect_core_message
    expect(last_message).to include("Please describe the outcome.")
    expect(last_message).to include("topic body")
    expect(last_message).not_to include("#{wizard_path}")
  end

  it "reopens the wizard with the submitted answers and links to it" do
    complete_wizard
    reviewable = queued_topic
    expect(reviewable.payload["wizard_id"]).to eq("super_mega_fun_wizard")

    result = revise(reviewable)

    expect(result.success?).to eq(true)
    expect(reviewable.reload.status).to eq("rejected")
    expect(last_message).to include("Please describe the outcome.")
    expect(last_message).to include("#{Discourse.base_url}#{wizard_path}")
    expect(wizard.start).to eq("step_1")
    expect(field_value("step_1_field_1")).to eq("Topic Title")
    expect(field_value("step_1_field_2")).to eq("topic body")
  end

  it "queues the corrected topic again when the reopened wizard is submitted" do
    complete_wizard
    revise(queued_topic)

    complete_wizard(body: "corrected body")

    pending = ReviewableQueuedPost.where(target_created_by: user, status: :pending)
    expect(pending.count).to eq(1)
    expect(pending.first.payload["title"]).to eq("Topic Title")
    expect(pending.first.payload["raw"]).to eq("corrected body")
    expect(pending.first.category_id).to eq(category.id)
  end

  it "sends the core message when the setting is disabled" do
    SiteSetting.custom_wizard_reopen_on_revise = false
    complete_wizard

    revise(queued_topic)

    expect_core_message
  end

  it "sends the core message when the topic was queued without the wizard id" do
    complete_wizard
    reviewable = queued_topic
    reviewable.update!(payload: reviewable.payload.except("wizard_id"))

    revise(reviewable)

    expect_core_message
  end

  it "sends the core message when the wizard can't be submitted again" do
    wizard_template["multiple_submissions"] = false
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    complete_wizard

    revise(queued_topic)

    expect_core_message
  end

  it "keeps a draft with answers and sends the core message" do
    complete_wizard
    reviewable = queued_topic
    submit_step("step_1", step_1_field_1: "Another Title", step_1_field_2: "work in progress")

    revise(reviewable)

    expect_core_message
    expect(field_value("step_1_field_2")).to eq("work in progress")
  end

  it "leaves other queued topics to core" do
    reviewable =
      NewPostManager
        .new(user, title: "A regular topic title", raw: "regular body " * 5, category: category.id)
        .perform
        .reviewable

    revise(reviewable)

    expect(last_message).to include("regular body")
    expect(last_message).not_to include("/w/")
  end
end
