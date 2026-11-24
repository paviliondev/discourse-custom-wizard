# frozen_string_literal: true

describe "Revising a queued wizard topic" do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:moderator)
  fab!(:category) { Fabricate(:category, name: "Information documents") }
  fab!(:tag) { Fabricate(:tag, name: "public-notice") }
  fab!(:upload) { Fabricate(:upload, user: user, original_filename: "notice.png") }

  let(:review_page) { PageObjects::Pages::Review.new }
  let(:revise_modal) { PageObjects::Modals::ReviseAndRejectPost.new }

  def mapped(field_id)
    [{ type: "assignment", output: field_id, output_type: "wizard_field", output_connector: "set" }]
  end

  before do
    enable_subscription("standard")
    SiteSetting.custom_wizard_reopen_on_revise = true
    category.update!(topic_posting_review_mode: :everyone)

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

  # Submits the wizard as the steps controller does, which queues the topic.
  def submit_wizard
    wizard = CustomWizard::Builder.new("revise_wizard", user).build
    wizard.create_updater(
      "step_1",
      title: "Notice about the road closure",
      body: "The road is closed on the wrong date.",
      attachment: upload.as_json(only: %i[id url original_filename extension]),
      category: [category.id],
      tags: [tag.name],
    ).update
    CustomWizard::Builder.new("revise_wizard", user).build.cleanup_on_complete!
  end

  it "lets the author fix the topic in the prefilled wizard and queues it again" do
    submit_wizard
    reviewable = ReviewableQueuedPost.find_by(target_created_by: user)

    sign_in(moderator)
    review_page.visit_reviewable(reviewable)
    expect(page).to have_content("Notice about the road closure")
    review_page.select_bundled_action(reviewable, "revise_and_reject_post")
    expect(revise_modal).to be_open
    PageObjects::Components::SelectKit.new(
      ".revise-and-reject-reviewable__reason",
    ).select_row_by_value("other_reason")
    revise_modal.fill_reason("Wrong date")
    revise_modal.fill_feedback("Please correct the date.")
    revise_modal.click_primary_button
    expect(review_page).to have_reviewable_with_rejected_status(reviewable)
    expect(reviewable.reload).to be_rejected

    sign_in(user)
    message = Topic.private_messages_for_user(user).order(:created_at).last
    expect(message.first_post.raw).to include("Wrong date")
    visit(message.relative_url)
    find(".cooked a[href$='/w/revise-wizard']").click

    expect(page).to have_field(with: "Notice about the road closure")
    expect(find(".wizard-field.body .d-editor-input").value).to eq(
      "The road is closed on the wrong date.",
    )
    expect(page).to have_css(".wizard-field.attachment", text: "notice.png")
    expect(page).to have_css(".wizard-field.category", text: category.name)
    expect(page).to have_css(".wizard-field.tags", text: tag.name)

    find(".wizard-field.body .d-editor-input").fill_in(with: "The road is closed on Monday.")
    find(".wizard-btn.done").click

    expect(page).to have_no_css(".wizard-btn.done")
    reviewable = ReviewableQueuedPost.find_by(target_created_by: user, status: :pending)
    expect(reviewable.payload["raw"]).to eq("The road is closed on Monday.")
    expect(reviewable.payload["title"]).to eq("Notice about the road closure")
    expect(reviewable.category_id).to eq(category.id)
    expect(reviewable.payload["tags"]).to eq([tag.name])
    submission = PluginStore.get("revise_wizard_submissions", user.id).last
    expect(submission["attachment"]["id"]).to eq(upload.id)
  end
end
