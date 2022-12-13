import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { findAll, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";

acceptance("Admin | Submissions", function (needs) {
  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });
  needs.pretender((server, helper) => {
    server.get("admin/wizards/submissions", () => {
      return helper.response([
        { id: "this_is_testing_wizard", name: "This is testing wizard" },
      ]);
    });
    server.get("admin/wizards/submissions/this_is_testing_wizard", () => {
      return helper.response({
        wizard: {
          id: "this_is_testing_wizard",
          name: "This is testing wizard",
        },
        submissions: [
          {
            id: "1",
            fields: {
              step_1_field_1: {
                value:
                  "creating a text for this text area that is being displayed here.",
                type: "textarea",
                label: "label field",
              },
            },
            submitted_at: "2022-12-12T09:41:57-04:00",
            user: {
              id: 1,
              username: "someuser",
              name: null,
              avatar_template: "",
            },
          },
        ],
        total: 1,
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
  });
  test("viewing submissions fields tab", async (assert) => {
    await visit("/admin/wizards/submissions");
    const wizards = selectKit(".select-kit");
    assert.ok(
      query(".message-content").innerText.includes(
        "Select a wizard to see its submissions"
      ),
      "it displays submissions message"
    );
    assert.ok(
      query(".message-content").innerText.includes("Select a wizard"),
      "it displays list of wizards"
    );
    await wizards.expand();
    await wizards.selectRowByValue("this_is_testing_wizard");
    assert.ok(
      query(".message-content").innerText.includes(
        "You're viewing the submissions of the This is testing wizard"
      ),
      "it displays submissions for a selected wizard"
    );
    assert.ok(find("table"));
    assert.ok(
      findAll("table tbody tr").length >= 1,
      "Displays submissions list"
    );

    await wizards.expand();
    const li = find('[data-name="Select a wizard"]');
    await click(li);
    const wizardContainerDiv = find(".admin-wizard-container");
    assert.ok(wizardContainerDiv.children().length === 0, "the div is empty");
  });
});
