import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, find, findAll, visit } from "@ember/test-helpers";

acceptance("Admin | Manager", function (needs) {
  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });
  needs.pretender((server, helper) => {
    server.get("admin/wizards/manager", () => {
      return helper.response({
        failed: "FAILED",
        error: "Please select at least one valid wizard",
      });
    });

    server.get("admin/wizards/manager/this_is_testing_wizard", () => {
      return helper.response({
        wizard: {
          id: "this_is_testing_wizard",
          name: "This is testing wizard",
        },
        logs: [
          {
            date: "2022-12-13T05:32:38.906-04:00",
            action: "create_topic",
            username: "christin",
            message: "success: created topic - id: 119",
            user: {
              id: 55,
              username: "christin",
              name: "Sybil Ratke",
              avatar_template: "",
            },
          },
          {
            date: "2022-12-12T09:41:57.888-04:00",
            action: "create_topic",
            username: "someuser",
            message:
              "error: invalid topic params - title: ; post: creating a text for this text area that is being displayed here.",
            user: {
              id: 1,
              username: "someuser",
              name: null,
              avatar_template: "",
            },
          },
        ],
        total: 2,
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
  test("viewing manager fields content", async (assert) => {
    await visit("/admin/wizards/manager");
    assert.ok(
      query(".message-content").innerText.includes(
        "Export, import or destroy wizards"
      ),
      "it displays manager message"
    );
    assert.ok(
      find('table tr[data-wizard-id="this-is-testing-wizard"]'),
      "table shows the wizard content list"
    );

    const checkbox = findAll(
      'table tr[data-wizard-id="this-is-testing-wizard"] input[type="checkbox"]'
    );
    const exportCheck = checkbox[0];
    const destroyCheck = checkbox[1];

    // Find the button and check if it has the "selected" class
    const exportButton = find("#export-button");
    assert.ok(
      exportButton.hasAttribute("disabled"),
      "the export button is disabled when export checkbox is unchecked"
    );
    await click(exportCheck);
    assert.ok(
      !exportButton.hasAttribute("disabled"),
      "the export button is enabled when export checkbox is clicked"
    );
    await click(exportCheck);
    assert.ok(
      exportButton.hasAttribute("disabled"),
      "the export button is disabled when export checkbox is unchecked"
    );
    // destroy button
    const destroyButton = find("#destroy-button");
    assert.ok(
      destroyButton.hasAttribute("disabled"),
      "the destroy button is disabled when destroy checkbox is unchecked"
    );
    await click(destroyCheck);
    assert.ok(
      !destroyButton.hasAttribute("disabled"),
      "the destroy button is enabled when destroy checkbox is clicked"
    );
    await click(destroyCheck);
    assert.ok(
      destroyButton.hasAttribute("disabled"),
      "the destroy button is disabled when destroy checkbox is unchecked"
    );
  });
});
