# frozen_string_literal: true

describe DiscoursePluginStatistics::Plugin do
  let(:template_json) { get_wizard_fixture("wizard") }

  describe "#discourse_custom_wizard" do
    before do
      enable_subscription('standard')

      CustomWizard::Template.save(template_json, skip_jobs: true)

      template_json_2 = template_json.dup
      template_json_2["id"] = 'super_mega_fun_wizard_2'
      CustomWizard::Template.save(template_json_2, skip_jobs: true)

      @data = DiscoursePluginStatistics::Plugin.discourse_custom_wizard
    end

    it "includes a total wizard count" do
      expect(@data[:total_wizards]).to eq(2)
    end

    it "includes the subscription type" do
      expect(@data[:subscription_type]).to eq('standard')
    end

    it "includes a count of features being used across all wizards" do
      expect(@data[:subscription_features]).to eq(
        wizard: {
          save_submissions: 2,
          after_signup: 2,
          prompt_completion: 2,
          required: 0,
          permitted: 0,
        },
        step: {
          required_data: 0,
          permitted_params: 0,
          force_final: 0
        },
        field: {
          condition: 0,
          type: {
            text: 2,
            textarea: 2,
            text_only: 2,
            date: 2,
            time: 2,
            date_time: 2,
            number: 2,
            checkbox: 2,
            dropdown: 2,
            composer: 0,
            composer_preview: 0,
            url: 0,
            upload: 0,
            tag: 0,
            category: 0,
            group: 0,
            user_selector: 0,
          },
          realtime_validations: 0
        },
        action: {
          type: {
            create_topic: 2,
            send_message: 0,
            update_profile: 2,
            open_composer: 2,
            route_to: 2,
            send_to_api: 0,
            watch_categories: 0,
            watch_tags: 0,
            add_to_group: 0,
            create_group: 0,
            create_category: 0,
          }
        }
      )
    end
  end
end
