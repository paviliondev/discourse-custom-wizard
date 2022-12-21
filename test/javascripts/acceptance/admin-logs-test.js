import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { skip } from "qunit";
import { findAll, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";

acceptance("Admin | Logs", function (needs) {
  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });
  needs.pretender((server, helper) => {
    server.get("/admin/wizards/logs", () => {
      return helper.response([
        { id: "this_is_testing_wizard", name: "This is testing wizard" },
      ]);
    });
    server.get("/admin/wizards/logs/this_is_testing_wizard", () => {
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
    server.get("/admin/wizards/wizard", () => {
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
  skip("viewing logs fields tab", async (assert) => {
    await visit("/admin/wizards/logs");
    const wizards = selectKit(".select-kit");
    assert.ok(
      query(".message-content").innerText.includes(
        "Select a wizard to see its logs"
      ),
      "it displays logs message"
    );
    assert.ok(
      query(".message-content").innerText.includes("Select a wizard"),
      "it displays list of logs"
    );
    await wizards.expand();
    await wizards.selectRowByValue("this_is_testing_wizard");
    assert.ok(
      query(".message-content").innerText.includes(
        "View recent logs for wizards on the forum"
      ),
      "it displays logs for a selected wizard"
    );
    assert.ok(find("table"));
    assert.ok(findAll("table tbody tr").length === 2, "Displays logs list");

    const refreshButton = find(".refresh.btn");
    await click(refreshButton);
    assert.ok(find("table"));
    assert.ok(
      findAll("table tbody tr").length === 2,
      "Refresh button works correctly"
    );

    await wizards.expand();
    const li = find('[data-name="Select a wizard"]');
    await click(li);
    const wizardContainerDiv = find(".admin-wizard-container");
    assert.ok(wizardContainerDiv.children().length === 0, "the div is empty");
  });
});
