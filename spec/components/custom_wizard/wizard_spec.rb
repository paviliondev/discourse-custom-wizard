require 'rails_helper'

describe CustomWizard::Wizard do
  fab!(:user) { Fabricate(:user) }
  fab!(:trusted_user) { Fabricate(:user, trust_level: TrustLevel[3])}
  fab!(:admin_user) { Fabricate(:user, admin: true)}
  
  let(:template_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  }
  
  let(:permitted_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard/permitted.json"
    ).read)
  }
  
  before do
    Group.refresh_automatic_group!(:trust_level_3)
    
    @permitted_template = template_json.dup
    @permitted_template["permitted"] = permitted_json["permitted"]
    
    @wizard = CustomWizard::Wizard.new(template_json, user)
    template_json['steps'].each do |step_template|
      @wizard.append_step(step_template['id'])
    end
  end
  
  def progress_step(step_id, acting_user = user)
    UserHistory.create(
      action: UserHistory.actions[:custom_wizard_step],
      acting_user_id: acting_user.id,
      context: @wizard.id,
      subject: step_id
    )
  end    
    
  it "appends steps from a template" do
    expect(@wizard.steps.length).to eq(3)
  end
  
  it "determines the user's current step" do
    expect(@wizard.start.id).to eq('step_1')
    progress_step('step_1')
    expect(@wizard.start.id).to eq('step_2')
  end
  
  it "creates a step updater" do
    expect(
      @wizard.create_updater('step_1', step_1_field_1: "Text input")
        .class
    ).to eq(CustomWizard::StepUpdater)
  end
  
  it "determines whether a wizard is unfinished" do
    expect(@wizard.unfinished?).to eq(true)
    progress_step("step_1")
    expect(@wizard.unfinished?).to eq(true)
    progress_step("step_2")
    expect(@wizard.unfinished?).to eq(true)
    progress_step("step_3")
    expect(@wizard.unfinished?).to eq(false)
  end
  
  it "determines whether a wizard has been completed by a user" do
    expect(@wizard.completed?).to eq(false)
    progress_step("step_1")
    progress_step("step_2")
    progress_step("step_3")
    expect(@wizard.completed?).to eq(true)
  end
  
  it "is not completed if steps submitted before after time" do
    progress_step("step_1")
    progress_step("step_2")
    progress_step("step_3")
    
    template_json['after_time'] = true
    template_json['after_time_scheduled'] = Time.now + 3.hours
    
    wizard = CustomWizard::Wizard.new(template_json, user)
    
    expect(wizard.completed?).to eq(false)
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
    progress_step("step_1", trusted_user)
    progress_step("step_2", trusted_user)
    progress_step("step_3", trusted_user)
    
    expect(
      CustomWizard::Wizard.new(@permitted_template, trusted_user).can_access?
    ).to eq(true)
  end
  
  it "does not let an unpermitted user access a complete wizard without multiple submissions" do
    progress_step("step_1", trusted_user)
    progress_step("step_2", trusted_user)
    progress_step("step_3", trusted_user)
    
    @permitted_template['multiple_submissions'] = false
    
    expect(
      CustomWizard::Wizard.new(@permitted_template, trusted_user).can_access?
    ).to eq(false)
  end
  
  it "lists the site groups" do
    expect(@wizard.groups.length).to eq(8)
  end
  
  it "lists the site categories" do
    expect(@wizard.categories.length).to eq(1)
  end
  
  context "submissions" do
    before do
      @wizard.set_submissions(step_1_field_1: 'I am a user submission')
    end
    
    it "sets the user's submission" do
      expect(
        PluginStore.get("#{template_json['id']}_submissions", user.id)
          .first['step_1_field_1']
      ).to eq('I am a user submission')
    end
    
    it "lists the user's submissions" do
      expect(@wizard.submissions.length).to eq(1)
    end
    
    it "returns the user's current submission" do
      expect(@wizard.current_submission['step_1_field_1']).to eq('I am a user submission')
    end
  end
  
  it "provides class methods to set and list submissions" do
    CustomWizard::Wizard.set_submissions(template_json['id'], user,
      step_1_field_1: 'I am a user submission'
    )
    expect(
      CustomWizard::Wizard.submissions(template_json['id'], user)
        .first['step_1_field_1']
    ).to eq('I am a user submission')
  end

  context do
    before do
      CustomWizard::Template.save(@permitted_template, skip_jobs: true)
      
      template_json_2 = template_json.dup
      template_json_2["id"] = 'super_mega_fun_wizard_2'
      template_json_2["prompt_completion"] = true
      CustomWizard::Template.save(template_json_2, skip_jobs: true)
      
      template_json_3 = template_json.dup
      template_json_3["id"] = 'super_mega_fun_wizard_3'
      template_json_3["after_signup"] = true
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
  end
  
  it "sets wizard redirects if user is permitted" do
    CustomWizard::Template.save(@permitted_template, skip_jobs: true)
    CustomWizard::Wizard.set_wizard_redirect('super_mega_fun_wizard', trusted_user)
    expect(
      trusted_user.custom_fields['redirect_to_wizard']
    ).to eq("super_mega_fun_wizard")
  end
  
  it "does not set a wizard redirect if user is not permitted" do
    CustomWizard::Template.save(@permitted_template, skip_jobs: true)
    CustomWizard::Wizard.set_wizard_redirect('super_mega_fun_wizard', user)
    expect(
      trusted_user.custom_fields['redirect_to_wizard']
    ).to eq(nil)
  end
end