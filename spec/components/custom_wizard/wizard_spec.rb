# frozen_string_literal: true

describe CustomWizard::Wizard do
  fab!(:user) { Fabricate(:user) }
  fab!(:trusted_user) { Fabricate(:user, trust_level: TrustLevel[3]) }
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  let(:template_json) { get_wizard_fixture("wizard") }
  let(:permitted_json) { get_wizard_fixture("wizard/permitted") }
  let(:guests_permitted_json) { get_wizard_fixture("wizard/guests_permitted") }
  let(:step_json) { get_wizard_fixture("step/step") }

  before do
    Group.refresh_automatic_group!(:trust_level_3)
    @permitted_template = template_json.dup
    @permitted_template["permitted"] = permitted_json["permitted"]
    @guests_permitted_template = template_json.dup
    @guests_permitted_template["permitted"] = guests_permitted_json["permitted"]
    @wizard = CustomWizard::Wizard.new(template_json, user)
  end

  def append_steps
    template_json['steps'].each do |step_template|
      @wizard.append_step(step_template['id'])
    end
    @wizard.update!
  end

  def progress_step(step_id, actor_id: user.id, wizard: @wizard)
    CustomWizard::UserHistory.create(
      action: CustomWizard::UserHistory.actions[:step],
      actor_id: actor_id,
      context: wizard.id,
      subject: step_id
    )
    @wizard.update!
  end

  it "appends steps" do
    append_steps
    expect(@wizard.steps.length).to eq(3)
  end

  it "appends steps with indexes" do
    append_steps
    expect(@wizard.steps.first.index).to eq(0)
    expect(@wizard.steps.last.index).to eq(2)
  end

  it "appends steps with custom indexes" do
    template_json['steps'][0]['index'] = 2
    template_json['steps'][1]['index'] = 1
    template_json['steps'][2]['index'] = 0

    template_json['steps'].each do |step_template|
      @wizard.append_step(step_template['id']) do |step|
        step.index = step_template['index'] if step_template['index']
      end
    end

    expect(@wizard.steps.first.index).to eq(2)
    expect(@wizard.steps.last.index).to eq(0)

    @wizard.update!

    expect(@wizard.steps.first.id).to eq("step_3")
    expect(@wizard.steps.last.id).to eq("step_1")

    expect(@wizard.steps.first.next.id).to eq("step_2")
    expect(@wizard.steps.last.next).to eq(nil)
  end

  it "determines the user's current step" do
    append_steps
    expect(@wizard.start).to eq('step_1')
    progress_step('step_1')
    expect(@wizard.start).to eq('step_2')
  end

  it "determines the user's current step if steps are added" do
    append_steps
    progress_step('step_1')
    progress_step('step_2')
    progress_step("step_3")

    fourth_step = step_json.dup
    fourth_step['id'] = "step_4"
    template = template_json.dup
    template['steps'] << fourth_step

    CustomWizard::Template.save(template, skip_jobs: true)

    wizard = CustomWizard::Wizard.new(template, user)
    template['steps'].each do |step_template|
      wizard.append_step(step_template['id'])
    end

    expect(wizard.steps.size).to eq(4)
    expect(wizard.start).to eq(nil)
  end

  it "creates a step updater" do
    expect(
      @wizard.create_updater('step_1', step_1_field_1: "Text input")
        .class
    ).to eq(CustomWizard::StepUpdater)
  end

  it "determines whether a wizard is unfinished" do
    append_steps
    expect(@wizard.unfinished?).to eq(true)
    progress_step("step_1")
    expect(@wizard.unfinished?).to eq(true)
    progress_step("step_2")
    expect(@wizard.unfinished?).to eq(true)
    progress_step("step_3")
    expect(@wizard.unfinished?).to eq(false)
  end

  it "determines whether a wizard has been completed by a user" do
    append_steps
    expect(@wizard.completed?).to eq(false)
    progress_step("step_1")
    progress_step("step_2")
    progress_step("step_3")
    expect(@wizard.completed?).to eq(true)
  end

  it "is not completed if steps submitted before after time" do
    append_steps

    progress_step("step_1")
    progress_step("step_2")
    progress_step("step_3")

    template_json['after_time'] = true
    template_json['after_time_scheduled'] = Time.now + 3.hours

    wizard = CustomWizard::Wizard.new(template_json, user)
    expect(wizard.completed?).to eq(false)
  end

  context "with subscription" do
    before do
      enable_subscription("standard")
    end

    it "permits admins" do
      expect(
        CustomWizard::Wizard.new(@permitted_template, admin_user).permitted?
      ).to eq(true)
    end

    it "permits permitted users" do
      expect(
        CustomWizard::Wizard.new(@permitted_template, trusted_user).permitted?
      ).to eq(true)
    end

    it "permits everyone if everyone is permitted" do
      @permitted_template['permitted'][0]['output'] = Group::AUTO_GROUPS[:everyone]
      expect(
        CustomWizard::Wizard.new(@permitted_template, user).permitted?
      ).to eq(true)
    end

    it "does not permit unpermitted users" do
      expect(
        CustomWizard::Wizard.new(@permitted_template, user).permitted?
      ).to eq(false)
    end

    it "does not let an unpermitted user access a wizard" do
      expect(
        CustomWizard::Wizard.new(@permitted_template, user).can_access?
      ).to eq(false)
    end

    it "lets a permitted user access an incomplete wizard" do
      expect(
        CustomWizard::Wizard.new(@permitted_template, trusted_user).can_access?
      ).to eq(true)
    end

    it "lets a permitted user access a complete wizard with multiple submissions" do
      append_steps

      progress_step("step_1", actor_id: trusted_user.id)
      progress_step("step_2", actor_id: trusted_user.id)
      progress_step("step_3", actor_id: trusted_user.id)

      @permitted_template["multiple_submissions"] = true

      expect(
        CustomWizard::Wizard.new(@permitted_template, trusted_user).can_access?
      ).to eq(true)
    end

    it "does not let an unpermitted user access a complete wizard without multiple submissions" do
      append_steps

      progress_step("step_1", actor_id: trusted_user.id)
      progress_step("step_2", actor_id: trusted_user.id)
      progress_step("step_3", actor_id: trusted_user.id)

      @permitted_template['multiple_submissions'] = false

      expect(
        CustomWizard::Wizard.new(@permitted_template, trusted_user).can_access?
      ).to eq(false)
    end

    it "sets wizard redirects if user is permitted" do
      CustomWizard::Template.save(@permitted_template, skip_jobs: true)
      CustomWizard::Wizard.set_user_redirect('super_mega_fun_wizard', trusted_user)
      expect(
        trusted_user.custom_fields['redirect_to_wizard']
      ).to eq("super_mega_fun_wizard")
    end

    it "does not set a wizard redirect if user is not permitted" do
      CustomWizard::Template.save(@permitted_template, skip_jobs: true)
      CustomWizard::Wizard.set_user_redirect('super_mega_fun_wizard', user)
      expect(
        trusted_user.custom_fields['redirect_to_wizard']
      ).to eq(nil)
    end
  end

  context "with subscription and restart upon revisit" do
    before do
      enable_subscription("standard")
      @wizard.restart_on_revisit = true
      CustomWizard::Template.save(@wizard.as_json)
    end

    it "returns to step 1 if option to clear submissions on each visit is set" do
      append_steps
      expect(@wizard.unfinished?).to eq(true)
      progress_step('step_1')
      expect(@wizard.start).to eq('step_1')
    end
  end

  context "with subscription and guest wizard" do
    before do
      enable_subscription("standard")
    end

    it "permits admins" do
      expect(
        CustomWizard::Wizard.new(@guests_permitted_template, admin_user).permitted?
      ).to eq(true)
    end

    it "permits regular users" do
      expect(
        CustomWizard::Wizard.new(@guests_permitted_template, user).permitted?
      ).to eq(true)
    end

    it "permits guests" do
      expect(
        CustomWizard::Wizard.new(@guests_permitted_template, nil, "guest123").permitted?
      ).to eq(true)
    end
  end

  context "submissions" do
    before do
      CustomWizard::Submission.new(@wizard, step_1_field_1: "I am a user submission").save
    end

    it "lists the user's submissions" do
      expect(@wizard.submissions.length).to eq(1)
    end

    it "returns the user's current submission" do
      expect(@wizard.current_submission.fields["step_1_field_1"]).to eq("I am a user submission")
    end
  end

  context "class methods" do
    before do
      enable_subscription("standard")
      CustomWizard::Template.save(@permitted_template, skip_jobs: true)

      template_json_2 = template_json.dup
      template_json_2["id"] = 'super_mega_fun_wizard_2'
      template_json_2["prompt_completion"] = true
      CustomWizard::Template.save(template_json_2, skip_jobs: true)

      template_json_3 = template_json.dup
      template_json_3["id"] = 'super_mega_fun_wizard_3'
      template_json_3["after_signup"] = true
      template_json_3["prompt_completion"] = true
      CustomWizard::Template.save(template_json_3, skip_jobs: true)
    end

    it "lists wizards the user can see" do
      expect(CustomWizard::Wizard.list(user).length).to eq(2)
      expect(CustomWizard::Wizard.list(trusted_user).length).to eq(3)
    end

    it "returns the first after signup wizard" do
      expect(CustomWizard::Wizard.after_signup(user).id).to eq('super_mega_fun_wizard_3')
    end

    it "lists prompt completion wizards" do
      expect(CustomWizard::Wizard.prompt_completion(user).length).to eq(2)
    end

    it "prompt completion does not include wizards user has completed" do
      wizard_2 = CustomWizard::Wizard.new(CustomWizard::Template.find('super_mega_fun_wizard_2'), user)
      progress_step("step_1", wizard: wizard_2)
      progress_step("step_2", wizard: wizard_2)
      progress_step("step_3", wizard: wizard_2)
      expect(CustomWizard::Wizard.prompt_completion(user).length).to eq(1)
    end
  end
end
