import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";

acceptance("Admin | Custom Wizard", function (needs) {
  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });

  needs.pretender((server, helper) => {
    server.get("admin/wizards/wizard", () => {
      return helper.response({
        wizard_list: [
          { id: "this_is_testing_wizard", name: "This is testing wizard" },
        ],
        field_types: {
          text: {
            min_length: null,
            max_length: null,
            prefill: null,
            char_counter: null,
            validations: null,
            placeholder: null,
          },
          textarea: {
            min_length: null,
            max_length: null,
            prefill: null,
            char_counter: null,
            placeholder: null,
          },
          composer: {
            min_length: null,
            max_length: null,
            char_counter: null,
            placeholder: null,
          },
          text_only: {},
          composer_preview: { preview_template: null },
          date: { format: "YYYY-MM-DD" },
          time: { format: "HH:mm" },
          date_time: { format: "" },
          number: {},
          checkbox: {},
          url: { min_length: null },
          upload: { file_types: ".jpg,.jpeg,.png" },
          dropdown: { prefill: null, content: null },
          tag: { limit: null, prefill: null, content: null, tag_groups: null },
          category: { limit: 1, property: "id", prefill: null, content: null },
          group: { prefill: null, content: null },
          user_selector: {},
        },
        realtime_validations: {
          similar_topics: {
            types: ["text"],
            component: "similar-topics-validator",
            backend: true,
            required_params: [],
          },
        },
        custom_fields: [
          {
            id: "external",
            klass: "category",
            name: "require_topic_approval",
            type: "boolean",
            serializers: null,
          },
          {
            id: "external",
            klass: "category",
            name: "require_reply_approval",
            type: "boolean",
            serializers: null,
          },
          {
            id: "external",
            klass: "category",
            name: "num_auto_bump_daily",
            type: "integer",
            serializers: null,
          },
          {
            id: "external",
            klass: "category",
            name: "has_chat_enabled",
            type: "boolean",
            serializers: null,
          },
          {
            id: "external",
            klass: "post",
            name: "missing uploads",
            type: "json",
            serializers: null,
          },
          {
            id: "external",
            klass: "post",
            name: "missing uploads ignored",
            type: "boolean",
            serializers: null,
          },
          {
            id: "external",
            klass: "post",
            name: "notice",
            type: "json",
            serializers: null,
          },
          {
            id: "external",
            klass: "post",
            name: "local_dates",
            type: "json",
            serializers: null,
          },
          {
            id: "external",
            klass: "post",
            name: "has_polls",
            type: "boolean",
            serializers: null,
          },
        ],
      });
    });
    server.get("/admin/wizards", () => {
      return helper.response({
        subscribed: false,
        subscription_type: "none",
        subscription_attributes: {
          wizard: {
            required: {
              none: [],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
            permitted: {
              none: [],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
            restart_on_revisit: {
              none: [],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
          },
          step: {
            condition: {
              none: [],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
            required_data: {
              none: [],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
            permitted_params: {
              none: [],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
          },
          field: {
            condition: {
              none: [],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
            type: {
              none: [
                "text",
                "textarea",
                "text_only",
                "date",
                "time",
                "date_time",
                "number",
                "checkbox",
                "dropdown",
                "upload",
              ],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
            realtime_validations: {
              none: [],
              standard: ["*"],
              business: ["*"],
              community: ["*"],
            },
          },
          action: {
            type: {
              none: [
                "create_topic",
                "update_profile",
                "open_composer",
                "route_to",
              ],
              standard: [
                "create_topic",
                "update_profile",
                "open_composer",
                "route_to",
                "send_message",
                "watch_categories",
                "add_to_group",
              ],
              business: ["*"],
              community: ["*"],
            },
          },
          custom_field: {
            klass: {
              none: ["topic", "post"],
              standard: ["topic", "post"],
              business: ["*"],
              community: ["*"],
            },
            type: {
              none: ["string", "boolean", "integer"],
              standard: ["string", "boolean", "integer"],
              business: ["*"],
              community: ["*"],
            },
          },
          api: {
            all: { none: [], standard: [], business: ["*"], community: ["*"] },
          },
        },
        subscription_client_installed: false,
      });
    });
    server.get("admin/wizards/api", () => {
      return helper.response({ success: "OK" });
    });
    server.get("admin/customize/user_fields", () => {
      return helper.response({ user_fields: [] });
    });
    server.get("admin/wizards/wizard/this_is_testing_wizard", () => {
      return helper.response({
        id: "this_is_testing_wizard",
        name: "This is testing wizard",
        save_submissions: true,
        after_time: false,
        after_time_scheduled: "2022-12-12T13:45:00.000Z",
        prompt_completion: true,
        steps: [
          {
            id: "step_1",
            title: "step 1",
            raw_description: "This is a description for step 1 sads",
            fields: [
              {
                id: "step_1_field_1",
                label: "label field",
                description: "this is the label description",
                type: "textarea",
                placeholder: "insert a textarea text here.",
              },
            ],
            description: "This is a description for step 1 sads",
          },
        ],
        actions: [
          {
            id: "action_1",
            run_after: "wizard_completion",
            type: "create_topic",
            skip_redirect: false,
            post: "step_1_field_1",
            post_builder: false,
            title: [
              {
                type: "assignment",
                output: "Testing title",
                output_type: "text",
                output_connector: "set",
                pairs: [],
              },
            ],
            category: [
              {
                type: "assignment",
                output_type: "category",
                output_connector: "set",
                output: [30],
              },
            ],
          },
        ],
      });
    });
  });

  test("viewing content for a selected wizard", async (assert) => {
    await visit("/admin/wizards/wizard");
    assert.ok(
      query(".message-content").innerText.includes(
        "Select a wizard, or create a new one"
      ),
      "it displays wizard message"
    );
    const wizards = selectKit(".select-kit");
    await wizards.expand();
    await wizards.selectRowByValue("this_is_testing_wizard");
    assert.ok(
      query(".message-content").innerText.includes("You're editing a wizard"),
      "it displays wizard message for a selected wizard"
    );
    await wizards.expand();
    const li = find('[data-name="Select a wizard"]');
    await click(li);
    const wizardContainerDiv = find(".admin-wizard-container");
    assert.ok(wizardContainerDiv.children().length === 0, "the div is empty");
  });
});
