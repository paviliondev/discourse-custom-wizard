# frozen_string_literal: true

describe CustomWizardReviewableQueuedPost do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:moderator)
  fab!(:category)

  let(:wizard_template) { get_wizard_fixture("wizard") }

  before do
    category.update!(topic_posting_review_mode: :everyone)
    wizard_template["multiple_submissions"] = true
    wizard_template["actions"][0]["visible"][0]["output"] = "false"
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
  end

  def build_wizard
    CustomWizard::Builder.new("super_mega_fun_wizard", user).build
  end

  def complete_wizard
    wizard = build_wizard
    wizard.create_updater(
      wizard.steps.first.id,
      step_1_field_1: "Topic Title",
      step_1_field_2: "topic body",
    ).update
    wizard.create_updater(wizard.steps.second.id, {}).update
    wizard.create_updater(wizard.steps.last.id, step_3_field_3: category.id).update
  end

  def revise(reviewable)
    reviewable.perform(
      moderator,
      :revise_and_reject_post,
      revise_reason: "Needs more detail",
      revise_feedback: "Please describe the outcome.",
    )
  end

  def field_value(wizard, field_id)
    wizard.steps.flat_map(&:fields).find { |field| field.id == field_id }.value
  end

  def last_message
    Topic.private_messages_for_user(user).order(:created_at).last&.first_post&.raw
  end

  it "reopens the wizard with the submitted answers and links to it" do
    complete_wizard
    reviewable = ReviewableQueuedPost.find_by(target_created_by: user)
    expect(reviewable.payload["wizard_id"]).to eq("super_mega_fun_wizard")

    result = revise(reviewable)

    expect(result.success?).to eq(true)
    expect(reviewable.reload.status).to eq("rejected")
    expect(last_message).to include("Please describe the outcome.")
    expect(last_message).to include("#{Discourse.base_url}/w/super-mega-fun-wizard")

    wizard = build_wizard
    expect(wizard.start).to eq(wizard.steps.first.id)
    expect(field_value(wizard, "step_1_field_1")).to eq("Topic Title")
    expect(field_value(wizard, "step_1_field_2")).to eq("topic body")
  end

  it "queues the corrected topic again when the reopened wizard is submitted" do
    complete_wizard
    revise(ReviewableQueuedPost.find_by(target_created_by: user))

    # The client sends every field of a step, prefilled ones included.
    wizard = build_wizard
    wizard.create_updater(
      wizard.steps.first.id,
      step_1_field_1: field_value(wizard, "step_1_field_1"),
      step_1_field_2: "corrected body",
    ).update
    wizard.create_updater(wizard.steps.second.id, {}).update
    wizard.create_updater(wizard.steps.last.id, step_3_field_3: category.id).update

    pending = ReviewableQueuedPost.where(target_created_by: user, status: :pending)
    expect(pending.count).to eq(1)
    expect(pending.first.payload["title"]).to eq("Topic Title")
    expect(pending.first.payload["raw"]).to eq("corrected body")
    expect(pending.first.category_id).to eq(category.id)
  end

  it "finds the wizard of a topic queued without its id" do
    complete_wizard
    reviewable = ReviewableQueuedPost.find_by(target_created_by: user)
    reviewable.update!(payload: reviewable.payload.except("wizard_id"))

    revise(reviewable)

    expect(last_message).to include("/w/super-mega-fun-wizard")
    expect(field_value(build_wizard, "step_1_field_1")).to eq("Topic Title")
  end

  it "sends the core message when the wizard can't be submitted again" do
    wizard_template["multiple_submissions"] = false
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    complete_wizard

    revise(ReviewableQueuedPost.find_by(target_created_by: user))

    expect(last_message).to include("Please describe the outcome.")
    expect(last_message).to include("topic body")
    expect(last_message).not_to include("/w/super-mega-fun-wizard")
  end

  it "leaves other queued topics to core" do
    manager =
      NewPostManager.new(
        user,
        title: "A regular topic title",
        raw: "regular body " * 5,
        category: category.id,
      )
    reviewable = manager.perform.reviewable

    revise(reviewable)

    expect(last_message).to include("regular body")
    expect(last_message).not_to include("/w/")
  end
end
