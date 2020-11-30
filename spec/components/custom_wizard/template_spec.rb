require_relative '../../plugin_helper'

describe CustomWizard::Template do
  fab!(:user) { Fabricate(:user) }
  
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
    CustomWizard::Template.save(template_json, skip_jobs: true)
  end
  
  it "saves wizard templates" do
    expect(
      PluginStoreRow.exists?(
        plugin_name: 'custom_wizard',
        key: 'super_mega_fun_wizard'
      )
    ).to eq(true)
  end
  
  it "finds wizard templates" do
    expect(
      CustomWizard::Template.find('super_mega_fun_wizard')['id']
    ).to eq('super_mega_fun_wizard')
  end
  
  it "removes wizard templates" do
    CustomWizard::Template.remove('super_mega_fun_wizard')
    expect(
      CustomWizard::Template.find('super_mega_fun_wizard')
    ).to eq(nil)
  end
  
  it "checks for wizard template existence" do
    expect(
      CustomWizard::Template.exists?('super_mega_fun_wizard')
    ).to eq(true)
  end
  
  context "wizard template list" do
    before do
      template_json_2 = template_json.dup
      template_json_2["id"] = 'super_mega_fun_wizard_2'
      template_json_2["permitted"] = permitted_json['permitted']
      CustomWizard::Template.save(template_json_2, skip_jobs: true)
      
      template_json_3 = template_json.dup
      template_json_3["id"] = 'super_mega_fun_wizard_3'
      template_json_3["after_signup"] = true
      CustomWizard::Template.save(template_json_3, skip_jobs: true)
    end
    
    it "works" do
      expect(
        CustomWizard::Template.list.length
      ).to eq(3)
    end
    
    it "can be filtered by wizard settings" do
      expect(
        CustomWizard::Template.list(setting: "after_signup").length
      ).to eq(1)
    end
    
    it "can be ordered" do
      expect(
        CustomWizard::Template.list(
          order: "(value::json ->> 'permitted') IS NOT NULL DESC"
        ).first['id']
      ).to eq('super_mega_fun_wizard_2')
    end
  end
  
  context "after time setting" do
    before do
      freeze_time Time.now
      @scheduled_time = (Time.now + 3.hours).iso8601
      
      @after_time_template = template_json.dup
      @after_time_template["after_time"] = true
      @after_time_template["after_time_scheduled"] = @scheduled_time
    end
    
    it 'if enabled queues jobs after wizard is saved' do      
      expect_enqueued_with(job: :set_after_time_wizard, at: Time.parse(@scheduled_time).utc) do
        CustomWizard::Template.save(@after_time_template)
      end
    end
    
    it 'if disabled clears jobs after wizard is saved' do
      CustomWizard::Template.save(@after_time_template)
      @after_time_template['after_time'] = false
      
      expect_not_enqueued_with(job: :set_after_time_wizard) do
        CustomWizard::Template.save(@after_time_template)
      end
    end
  end
end