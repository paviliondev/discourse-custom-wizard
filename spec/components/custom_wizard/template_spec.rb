# frozen_string_literal: true

describe CustomWizard::Template do
  fab!(:user) { Fabricate(:user) }
  let(:template_json) { get_wizard_fixture("wizard") }
  let(:permitted_json) { get_wizard_fixture("wizard/permitted") }
  fab!(:upload) { Fabricate(:upload) }

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

  it "removes user wizard redirects if template is removed" do
    user.custom_fields['redirect_to_wizard'] = 'super_mega_fun_wizard'
    user.save_custom_fields(true)

    CustomWizard::Template.remove('super_mega_fun_wizard')
    expect(user.reload.custom_fields['redirect_to_wizard']).to eq(nil)
  end

  it "checks for wizard template existence" do
    expect(
      CustomWizard::Template.exists?('super_mega_fun_wizard')
    ).to eq(true)
  end

  context "upload references" do
    it "are added if a wizard has a step banner" do
      template_json['steps'][0]['banner'] = upload.url
      template_json['steps'][0]['banner_upload_id'] = upload.id
      CustomWizard::Template.save(template_json, skip_jobs: true)
      wizard_record = CustomWizard::Template.find_record(template_json["id"])
      expect(
        UploadReference.exists?(
          upload_id: upload.id,
          target_type: "PluginStoreRow",
          target_id: wizard_record.id
        )
      ).to eq(true)
    end

    it "are added if a wizard has a field image" do
      template_json['steps'][0]["fields"][0]['image'] = upload.url
      template_json['steps'][0]["fields"][0]['image_upload_id'] = upload.id
      CustomWizard::Template.save(template_json, skip_jobs: true)
      wizard_record = CustomWizard::Template.find_record(template_json["id"])
      expect(
        UploadReference.exists?(
          upload_id: upload.id,
          target_type: "PluginStoreRow",
          target_id: wizard_record.id
        )
      ).to eq(true)
    end

    it "are removed if a wizard step banner is removed" do
      template_json['steps'][0]['banner'] = upload.url
      template_json['steps'][0]['banner_upload_id'] = upload.id
      CustomWizard::Template.save(template_json, skip_jobs: true)

      template_json['steps'][0]['banner'] = nil
      template_json['steps'][0]['banner_upload_id'] = nil
      CustomWizard::Template.save(template_json, skip_jobs: true)
      wizard_record = CustomWizard::Template.find_record(template_json["id"])
      expect(
        UploadReference.exists?(target_type: "PluginStoreRow")
      ).to eq(false)
    end

    it "are removed if a wizard field image is removed" do
      template_json['steps'][0]["fields"][0]['image'] = upload.url
      template_json['steps'][0]["fields"][0]['image_upload_id'] = upload.id
      CustomWizard::Template.save(template_json, skip_jobs: true)

      template_json['steps'][0]["fields"][0]['image'] = nil
      template_json['steps'][0]["fields"][0]['image_upload_id'] = nil
      CustomWizard::Template.save(template_json, skip_jobs: true)
      wizard_record = CustomWizard::Template.find_record(template_json["id"])
      expect(
        UploadReference.exists?(target_type: "PluginStoreRow")
      ).to eq(false)
    end

    it "are removed if a wizard is removed" do
      template_json['steps'][0]["fields"][0]['image'] = upload.url
      template_json['steps'][0]["fields"][0]['image_upload_id'] = upload.id
      CustomWizard::Template.save(template_json, skip_jobs: true)
      CustomWizard::Template.remove(template_json["id"])
      expect(
        UploadReference.exists?(target_type: "PluginStoreRow")
      ).to eq(false)
    end
  end

  context "wizard template list" do
    before do
      enable_subscription('standard')

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
