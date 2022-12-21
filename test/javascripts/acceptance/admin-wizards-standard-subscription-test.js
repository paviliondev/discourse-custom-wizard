import {
  acceptance,
  query,
  visible,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { findAll, settled, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";

acceptance("Admin | Custom Wizard Standard Subscription", function (needs) {
  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });

  needs.pretender((server, helper) => {
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
    server.get("/admin/wizards/custom-fields", () => {
      return helper.response({
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
        subscribed: true,
        subscription_type: "standard",
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
    server.get("/admin/wizards/api", () => {
      return helper.response({ success: "OK" });
    });
    server.get("/admin/customize/user_fields", () => {
      return helper.response({ user_fields: [] });
    });
    server.get("/admin/wizards/wizard/this_is_testing_wizard", () => {
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
    server.put("/admin/wizards/wizard/new_wizard_for_testing", () => {
      return helper.response({
        success: "OK",
        wizard_id: "new_wizard_for_testing",
      });
    });
    server.get("/admin/wizards/wizard/new_wizard_for_testing", () => {
      return helper.response({
        id: "new_wizard_for_testing",
        name: "new wizard for testing",
        save_submissions: true,
        steps: [
          {
            id: "step_1",
            fields: [
              {
                id: "step_1_field_1",
                type: "text",
                validations: {
                  similar_topics: {},
                },
              },
            ],
          },
        ],
        actions: [
          {
            id: "action_1",
            run_after: "wizard_completion",
            type: "create_topic",
          },
        ],
      });
    });
  });

  test("creting a new wizard", async (assert) => {
    await visit("/admin/wizards/wizard");
    await settled();
    await click('button:contains("Create Wizard")');
    await settled();
    assert.ok(
      query(".message-content").innerText.includes(
        "You're creating a new wizard"
      ),
      "it displays wizard creation message"
    );
    assert.step("Step 1: Inserting a title");
    const wizardTitle = "New wizard for testing";
    await fillIn(".wizard-header input", wizardTitle);
    await settled();
    assert.equal(
      $(".wizard-header input").val(),
      wizardTitle,
      "The title input is inserted"
    );
    const wizardLink = find("div.wizard-url a");
    assert.equal(wizardLink.length, 1, "Wizard link was created");
    assert.notEqual(
      $.trim($("a[title='Subscribe to use these features']").text()),
      "Not Subscribed",
      "Don't show messsage of unsubscribed user"
    );
    assert.equal(
      find(".wizard-subscription-container a:contains('Subscribed')").length,
      1,
      "Wizard subscription features are accesible"
    );
    const subsFeature = find(
      ".wizard-subscription-container .subscription-settings .setting-value input"
    );
    await click(subsFeature);
    await settled();
    assert.ok(subsFeature.is(":checked"), "subscription feature available");
    assert.step("Step 2: Creating a step section");
    const stepAddBtn = find(".step .link-list button:contains('Add')");
    await click(stepAddBtn);
    await settled();
    const stepOneText = "step_1 (step_1)";
    const stepOneBtn = find(`.step button:contains(${stepOneText})`);
    assert.equal(stepOneBtn.length, 1, "Creating a step");
    const stepTitle = "step title";
    await fillIn(".wizard-custom-step input[name='title']", stepTitle);
    await settled();
    const stepButtonText = $.trim(
      $(".step div[data-id='step_1'] button").text()
    );
    assert.ok(
      stepButtonText.includes(stepTitle),
      "The step button changes according to title"
    );
    assert.equal(
      find(".wizard-subscription-container a:contains('Subscribed')").length,
      2,
      "Steps subscription features are accesible"
    );
    assert.step("Step 3: Creating a field section");
    const fieldAddBtn = find(".field .link-list button:contains('Add')");
    await click(fieldAddBtn);
    await settled();
    assert.ok(
      !visible(".wizard-custom-field button.undo-changes"),
      "clear button is not rendered"
    );
    const fieldOneText = "step_1_field_1 (step_1_field_1)";
    const fieldOneBtn = find(`.field button:contains(${fieldOneText})`);
    assert.equal(fieldOneBtn.length, 1, "Creating a field");
    const fieldTitle = "field title";
    await fillIn(".wizard-custom-field input[name='label']", fieldTitle);
    await settled();
    assert.ok(
      visible(".wizard-custom-field button.undo-changes"),
      "clear button is rendered after filling content"
    );
    let fieldButtonText = $.trim(
      $(".field div[data-id='step_1_field_1'] button").text()
    );
    assert.ok(
      fieldButtonText.includes(fieldTitle),
      "The step button changes according to title"
    );
    const clearBtn = find(`.wizard-custom-field button.undo-changes`);
    await click(clearBtn);
    await settled();
    fieldButtonText = $(".field div[data-id='step_1_field_1'] button")
      .text()
      .trim();
    assert.ok(
      fieldButtonText.includes("step_1_field_1 (step_1_field_1)"),
      "The field button changes to default title after clear button is clicked"
    );
    const fieldTypeDropdown = selectKit(
      ".wizard-custom-field .setting-value .select-kit"
    );
    await fieldTypeDropdown.expand();
    await fieldTypeDropdown.selectRowByValue("text");
    await settled();
    assert.ok(
      query(".wizard-custom-field .message-content").innerText.includes(
        "You're editing a field"
      ),
      "Text tipe for field correctly selected"
    );

    assert.equal(
      find(".wizard-subscription-container a:contains('Subscribed')").length,
      3,
      "Field subscription features are accesible"
    );
    assert.step("Step 4: Creating a action section");
    const actionAddBtn = find(".action .link-list button:contains('Add')");
    await click(actionAddBtn);
    await settled();
    const actionOneText = "action_1 (action_1)";
    const actionOneBtn = find(`.action button:contains(${actionOneText})`);
    assert.equal(actionOneBtn.length, 1, "Creating an action");
    assert.ok(
      query(
        ".wizard-custom-action .wizard-message .message-content"
      ).innerText.includes("Select an action type"),
      "it displays wizard select action message"
    );
    const actionTypeDropdown = selectKit(
      ".wizard-custom-action .setting-value .select-kit"
    );
    await actionTypeDropdown.expand();
    await settled();
    const listEnabled = findAll(
      ".wizard-custom-action .setting .setting-value ul li:not(.disabled)"
    );
    const listDisabled = findAll(
      ".wizard-custom-action .setting .setting-value ul li.disabled"
    );

    assert.ok(
      listDisabled.length === 3,
      "Disabled items displayed correctly in action dropdown"
    );
    assert.ok(
      listEnabled.length === 7,
      "Enabled items displayed correctly in action dropdown"
    );
    await actionTypeDropdown.selectRowByValue("create_topic");
    await settled();
    assert.ok(
      query(".wizard-custom-action .message-content").innerText.includes(
        "You're editing an action"
      ),
      "Create type action correctly selected"
    );
    let listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 10,
      "Display all settings of create topic"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("send_message");
    await settled();
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 9,
      "Display all settings of send message"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("watch_categories");
    await settled();
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 7,
      "Display all settings of watch categories"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("add_to_group");
    await settled();
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 3,
      "Display all settings of add to group"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("create_topic");
    await settled();
    assert.step("Step 5: Save wizard");
    const saveButton = find(
      '.admin-wizard-buttons button:contains("Save Changes")'
    );
    assert.ok(
      !visible('.admin-wizard-buttons button:contains("Delete Wizard")'),
      "delete wizard button not displayed"
    );
    await click(saveButton);
    await settled();
    assert.equal(
      currentURL(),
      "/admin/wizards/wizard/new_wizard_for_testing",
      "clicking the button navigates to the correct URL"
    );
    assert.ok(
      visible('.admin-wizard-buttons button:contains("Delete Wizard")'),
      "delete wizard button visible"
    );
    assert.verifySteps(
      [
        "Step 1: Inserting a title",
        "Step 2: Creating a step section",
        "Step 3: Creating a field section",
        "Step 4: Creating a action section",
        "Step 5: Save wizard",
      ],
      "All steps completed"
    );
  });
});
