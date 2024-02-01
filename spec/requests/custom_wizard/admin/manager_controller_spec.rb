# frozen_string_literal: true

describe CustomWizard::AdminManagerController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  let(:template) { get_wizard_fixture("wizard") }

  before do
    sign_in(admin_user)

    template_2 = template.dup
    template_2["id"] = 'super_mega_fun_wizard_2'
    template_3 = template.dup
    template_3["id"] = 'super_mega_fun_wizard_3'
    @template_array = [template, template_2, template_3]

    FileUtils.mkdir_p(concurrency_safe_tmp_dir) unless Dir.exist?(concurrency_safe_tmp_dir)
    @tmp_file_path = File.join(concurrency_safe_tmp_dir, SecureRandom.hex << 'wizards.json')
    File.write(@tmp_file_path, @template_array.to_json)
  end

  it 'exports all the wizard templates' do
    @template_array.each do |template|
      CustomWizard::Template.save(template, skip_jobs: true)
    end

    get '/admin/wizards/manager/export.json', params: {
      wizard_ids: [
        'super_mega_fun_wizard',
        'super_mega_fun_wizard_2',
        'super_mega_fun_wizard_3'
      ]
    }

    expect(response.status).to eq(200)
    expect(response.parsed_body).to match_array(@template_array)
  end

  context "import" do
    it "works" do
      templates = @template_array.map { |t| t.slice('id', 'name') }

      post '/admin/wizards/manager/import.json', params: {
        file: fixture_file_upload(File.open(@tmp_file_path))
      }

      expect(response.status).to eq(200)
      expect(response.parsed_body['imported']).to match_array(templates)
      expect(CustomWizard::Template.list.map { |t| t.slice('id', 'name') }).to match_array(templates)
    end

    it 'rejects a template with the same id as a saved template' do
      templates = @template_array.map { |t| t.slice('id', 'name') }

      post '/admin/wizards/manager/import.json', params: {
        file: fixture_file_upload(File.open(@tmp_file_path))
      }

      expect(response.status).to eq(200)
      expect(response.parsed_body['imported']).to match_array(templates)

      post '/admin/wizards/manager/import.json', params: {
        file: fixture_file_upload(File.open(@tmp_file_path))
      }

      expect(response.status).to eq(200)
      expect(response.parsed_body['failures']).to match_array(
        @template_array.map do |t|
          {
            id: t['id'],
            messages: I18n.t("wizard.validation.conflict", wizard_id: t['id'])
          }.as_json
        end
      )
    end
  end

  it 'destroys wizard templates' do
    templates = @template_array.map { |t| t.slice('id', 'name') }

    @template_array.each do |template|
      CustomWizard::Template.save(template, skip_jobs: true)
    end

    delete '/admin/wizards/manager/destroy.json', params: {
      wizard_ids: [
        'super_mega_fun_wizard',
        'super_mega_fun_wizard_2',
        'super_mega_fun_wizard_3'
      ]
    }

    expect(response.status).to eq(200)
    expect(response.parsed_body['destroyed']).to match_array(templates)
    expect(CustomWizard::Template.list.length).to eq(0)
  end
end
