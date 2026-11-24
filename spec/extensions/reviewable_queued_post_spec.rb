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
    # Same as the client, which sends the step fields as JSON.
    put "#{wizard_path}/steps/#{step_id}.json", params: { fields: fields }, as: :json
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
    reviewable.reload.perform(
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

  context "when a moderator uses the review queue" do
    def perform_in_queue(reviewable, action, params = {})
      sign_in(moderator)
      put "/review/#{reviewable.id}/perform/#{action}.json",
          params: { version: reviewable.reload.version }.merge(params)
      expect(response.status).to eq(200)
      sign_in(user)
    end

    let(:revise_params) do
      { revise_reason: "Other", revise_custom_reason: "Wrong date", revise_feedback: "" }
    end

    it "reopens the wizard when revising" do
      complete_wizard
      reviewable = queued_topic

      perform_in_queue(reviewable, :revise_and_reject_post, revise_params)

      expect(reviewable.reload.status).to eq("rejected")
      expect(last_message).to include("Wrong date")
      expect(last_message).to include("#{Discourse.base_url}#{wizard_path}")
      expect(field_value("step_1_field_2")).to eq("topic body")
    end

    it "reopens the wizard when revising with DSA reporting enabled" do
      enable_dsa_reporting(
        community_rules: [{ ground: "Be accurate", explanation: "Dates must be correct." }],
      )
      complete_wizard
      reviewable = queued_topic

      perform_in_queue(
        reviewable,
        :revise_and_reject_post,
        revise_params.merge(
          dsa_classification: {
            community_rule: DsaStatementOfRecord.community_rules.first.fetch("id"),
            category: "STATEMENT_CATEGORY_OTHER_VIOLATION_TC",
          },
        ),
      )

      expect(reviewable.reload.status).to eq("rejected")
      expect(last_message).to include("#{Discourse.base_url}#{wizard_path}")
    end

    it "approves wizard topics" do
      complete_wizard
      reviewable = queued_topic

      perform_in_queue(reviewable, :approve_post)

      expect(reviewable.reload.status).to eq("approved")
      topic = Topic.find_by(title: "Topic Title", category_id: category.id)
      expect(topic.first_post.raw).to eq("topic body")
      expect(topic.custom_fields["wizard_submission_id"]).to be_present
    end

    it "rejects wizard topics without reopening the wizard" do
      complete_wizard
      reviewable = queued_topic

      perform_in_queue(reviewable, :reject_post)

      expect(reviewable.reload.status).to eq("rejected")
      expect(field_value("step_1_field_2")).to be_blank
    end
  end

  it "sends the core message when reopening the wizard fails" do
    complete_wizard
    CustomWizard::Submission.stubs(:reopen).raises(StandardError, "reopen failed")

    result = revise(queued_topic)

    expect(result.success?).to eq(true)
    expect(queued_topic).to be_nil
    expect_core_message
  end

  context "when the topic is posted as another user" do
    fab!(:poster) { Fabricate(:user, trust_level: TrustLevel[2]) }

    before do
      wizard_template["actions"][0]["poster"] = [
        {
          type: "assignment",
          output: poster.username,
          output_type: "text",
          output_connector: "set",
        },
      ]
      CustomWizard::Template.save(wizard_template, skip_jobs: true)
    end

    it "sends the core message to the poster and doesn't reopen anyone's wizard" do
      complete_wizard
      reviewable = ReviewableQueuedPost.find_by(target_created_by: poster, status: :pending)

      revise(reviewable)

      message = Topic.private_messages_for_user(poster).order(:created_at).last.first_post.raw
      expect(message).to include("topic body")
      expect(message).not_to include(wizard_path)
      expect(PluginStore.get("super_mega_fun_wizard_submissions", poster.id)).to be_blank
      expect(field_value("step_1_field_2")).to be_blank
    end
  end

  context "with upload, category, tag and composer fields" do
    fab!(:tag)
    fab!(:upload) { Fabricate(:upload, user: user, original_filename: "image.png") }

    let(:wizard_path) { "/w/revise-wizard" }

    def mapped(field_id)
      [
        {
          type: "assignment",
          output: field_id,
          output_type: "wizard_field",
          output_connector: "set",
        },
      ]
    end

    def wizard
      CustomWizard::Builder.new("revise_wizard", user).build
    end

    def complete_wizard(body: "topic body")
      submit_step(
        "step_1",
        title: "Topic Title",
        body: body,
        attachment: upload.as_json(only: %i[id url original_filename extension]),
        category: [category.id],
        tags: [tag.name],
      )
    end

    before do
      enable_subscription("standard")
      CustomWizard::Template.save(
        {
          id: "revise_wizard",
          name: "Revise wizard",
          save_submissions: true,
          multiple_submissions: true,
          steps: [
            {
              id: "step_1",
              fields: [
                { id: "title", type: "text", label: "Title" },
                { id: "body", type: "composer", label: "Body" },
                { id: "attachment", type: "upload", label: "Attachment", file_types: ".png" },
                { id: "category", type: "category", label: "Category", limit: 1, property: "id" },
                { id: "tags", type: "tag", label: "Tags" },
              ],
            },
          ],
          actions: [
            {
              id: "action_1",
              type: "create_topic",
              run_after: "step_1",
              skip_redirect: true,
              title: mapped("title"),
              post: "body",
              category: mapped("category"),
              tags: mapped("tags"),
            },
          ],
        }.as_json,
        skip_jobs: true,
      )
    end

    it "prefills the reopened wizard with the submitted values" do
      complete_wizard
      reviewable = queued_topic
      expect(reviewable.payload["tags"]).to eq([tag.name])
      submitted = PluginStore.get("revise_wizard_submissions", user.id).sole

      revise(reviewable)

      get "#{wizard_path}.json"
      expect(response.status).to eq(200)
      values =
        response.parsed_body["steps"]
          .flat_map { |step| step["fields"] }
          .to_h { |field| [field["id"], field["value"]] }

      %w[title body attachment category tags].each do |field_id|
        expect(values[field_id]).to eq(submitted[field_id])
      end
      expect(values["attachment"]["id"]).to eq(upload.id)
      expect(values["category"]).to eq([category.id])
      expect(values["tags"]).to eq([tag.name])
    end

    it "queues the corrected topic with the same upload, category and tags" do
      complete_wizard
      revise(queued_topic)

      complete_wizard(body: "corrected body")

      reviewable = queued_topic
      expect(reviewable.payload["raw"]).to eq("corrected body")
      expect(reviewable.category_id).to eq(category.id)
      expect(reviewable.payload["tags"]).to eq([tag.name])
      submission = PluginStore.get("revise_wizard_submissions", user.id).last
      expect(submission["attachment"]["id"]).to eq(upload.id)
    end
  end
end
