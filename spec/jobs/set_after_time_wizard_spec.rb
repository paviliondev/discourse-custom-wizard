# frozen_string_literal: true

describe Jobs::SetAfterTimeWizard do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user, trust_level: TrustLevel[3]) }
  fab!(:user3) { Fabricate(:user, admin: true) }

  let(:template) { get_wizard_fixture("wizard") }
  let(:permitted_json) { get_wizard_fixture("wizard/permitted") }

  before do
    @after_time_template = template.dup
    @after_time_template["after_time"] = true
    @after_time_template["after_time_scheduled"] = (Time.now + 3.hours).iso8601
    CustomWizard::Template.save(@after_time_template)
  end

  it "sets wizard redirect for all users " do
    messages =
      MessageBus.track_publish("/redirect_to_wizard") do
        described_class.new.execute(wizard_id: "super_mega_fun_wizard")
      end
    expect(messages.first.data).to eq("super_mega_fun_wizard")
    expect(messages.first.user_ids).to match_array([user1.id, user2.id, user3.id])
    expect(
      UserCustomField.where(name: "redirect_to_wizard", value: "super_mega_fun_wizard").length,
    ).to eq(3)
  end

  context "when permitted is set" do
    before do
      enable_subscription("business")
      @after_time_template["permitted"] = permitted_json["permitted"]
      CustomWizard::Template.save(@after_time_template.as_json)
    end

    it "only redirects users in the group" do
      messages =
        MessageBus.track_publish("/redirect_to_wizard") do
          described_class.new.execute(wizard_id: "super_mega_fun_wizard")
        end
      expect(messages.first.data).to eq("super_mega_fun_wizard")
      expect(messages.first.user_ids).to match_array([user2.id])
      expect(
        UserCustomField.where(name: "redirect_to_wizard", value: "super_mega_fun_wizard").length,
      ).to eq(1)
    end
  end

  context "when after_time_groups is set" do
    fab!(:group1) { Fabricate(:group) }
    fab!(:group_user) { Fabricate(:group_user, group: group1, user: user2) }

    before do
      enable_subscription("business")
      @after_time_template["after_time_groups"] = [group1.name]
      CustomWizard::Template.save(@after_time_template.as_json)
    end

    it "only redirects users in the group" do
      messages =
        MessageBus.track_publish("/redirect_to_wizard") do
          described_class.new.execute(wizard_id: "super_mega_fun_wizard")
        end
      expect(messages.first.data).to eq("super_mega_fun_wizard")
      expect(messages.first.user_ids).to match_array([user2.id])
      expect(
        UserCustomField.where(name: "redirect_to_wizard", value: "super_mega_fun_wizard").length,
      ).to eq(1)
    end
  end

  context "when user has completed the wizard" do
    before do
      @after_time_template[:steps].each do |step|
        CustomWizard::UserHistory.create!(
          action: CustomWizard::UserHistory.actions[:step],
          actor_id: user1.id,
          context: @after_time_template[:id],
          subject: step[:id],
        )
      end
    end

    it "does not redirect to user" do
      messages =
        MessageBus.track_publish("/redirect_to_wizard") do
          described_class.new.execute(wizard_id: "super_mega_fun_wizard")
        end
      expect(messages.first.data).to eq("super_mega_fun_wizard")
      expect(messages.first.user_ids).to match_array([user2.id, user3.id])
      expect(
        UserCustomField.where(name: "redirect_to_wizard", value: "super_mega_fun_wizard").length,
      ).to eq(2)
    end
  end
end
