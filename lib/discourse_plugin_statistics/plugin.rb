# frozen_string_literal: true
module DiscoursePluginStatistics
  class Plugin
    def self.discourse_custom_wizard
      subscription_features = {
        wizard: {
          save_submissions: 0,
          after_signup: 0,
          prompt_completion: 0,
          required: 0,
          permitted: 0,
        },
        step: {
          required_data: 0,
          permitted_params: 0,
          force_final: 0,
        },
        field: {
          condition: 0,
          type: {
            text: 0,
            textarea: 0,
            text_only: 0,
            date: 0,
            time: 0,
            date_time: 0,
            number: 0,
            checkbox: 0,
            dropdown: 0,
            composer: 0,
            composer_preview: 0,
            url: 0,
            upload: 0,
            tag: 0,
            category: 0,
            topic: 0,
            group: 0,
            user_selector: 0,
          },
          realtime_validations: 0,
        },
        action: {
          type: {
            create_topic: 0,
            send_message: 0,
            update_profile: 0,
            open_composer: 0,
            route_to: 0,
            send_to_api: 0,
            watch_categories: 0,
            watch_tags: 0,
            add_to_group: 0,
            create_group: 0,
            create_category: 0,
          },
        },
      }

      increment_feature_count =
        lambda do |type, key, value|
          if key == "type"
            if !subscription_features[type.to_sym][:type][value.to_sym].nil?
              subscription_features[type.to_sym][:type][value.to_sym] += 1
            end
          else
            if !subscription_features[type.to_sym][key.to_sym].nil?
              subscription_features[type.to_sym][key.to_sym] += 1
            end
          end
        end

      CustomWizard::Template.list.each do |template|
        template.each { |key, value| increment_feature_count.call(:wizard, key, value) }
        template["steps"].each do |step|
          step.each { |key, value| increment_feature_count.call(:step, key, value) }
          step["fields"].each do |field|
            field.each { |key, value| increment_feature_count.call(:field, key, value) }
          end
        end
        template["actions"].each do |action|
          action.each { |key, value| increment_feature_count.call(:action, key, value) }
        end
      end

      {
        total_wizards: CustomWizard::Template.list.size,
        subscription_type: CustomWizard::Subscription.type.to_s,
        subscription_features: subscription_features,
      }
    end
  end
end
