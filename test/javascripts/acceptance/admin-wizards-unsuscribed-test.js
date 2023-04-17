import {
  acceptance,
  query,
  visible,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, findAll, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  getAdminTestingWizard,
  getCreatedWizard,
  getCustomFields,
  getUnsubscribedAdminWizards,
  getWizard,
} from "../helpers/admin-wizard";

acceptance("Admin | Custom Wizard Unsuscribed", function (needs) {
  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });

  needs.pretender((server, helper) => {
    server.get("/admin/wizards/wizard", () => {
      return helper.response(getWizard);
    });
    server.get("/admin/wizards/custom-fields", () => {
      return helper.response(getCustomFields);
    });
    server.get("/admin/wizards", () => {
      return helper.response(getUnsubscribedAdminWizards);
    });
    server.get("/admin/wizards/api", () => {
      return helper.response({ success: "OK" });
    });
    server.get("/admin/customize/user_fields", () => {
      return helper.response({ user_fields: [] });
    });
    server.get("/admin/wizards/wizard/this_is_testing_wizard", () => {
      return helper.response(getAdminTestingWizard);
    });
    server.put("/admin/wizards/wizard/new_wizard_for_testing", () => {
      return helper.response({
        success: "OK",
        wizard_id: "new_wizard_for_testing",
      });
    });
    server.get("/admin/wizards/wizard/new_wizard_for_testing", () => {
      return helper.response(getCreatedWizard);
    });
  });

  test("Displaying all tabs except API", async (assert) => {
    await visit("/admin/wizards");
    const list = find(".admin-controls li");
    const count = list.length;
    assert.equal(count, 5, "There should be 5 admin tabs");
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
    await click('[data-name="Select a wizard"]');
    const wizardContainerDiv = find(".admin-wizard-container");
    assert.ok(
      wizardContainerDiv.children().length === 0,
      "the content is empty when no wizard is selected"
    );
  });
  test("creting a new wizard", async (assert) => {
    await visit("/admin/wizards/wizard");
    await click(".admin-wizard-controls button");
    assert.ok(
      query(".message-content").innerText.includes(
        "You're creating a new wizard"
      ),
      "it displays wizard creation message"
    );
    const wizardTitle = "New wizard for testing";
    await fillIn(".wizard-header input", wizardTitle);
    assert.equal(
      $(".wizard-header input").val(),
      wizardTitle,
      "The title input is inserted"
    );
    const wizardLink = find("div.wizard-url a");
    assert.equal(wizardLink.length, 1, "Wizard link was created");
    assert.equal(
      $.trim($("a[title='Subscribe to use these features']").text()),
      "Not Subscribed",
      "Show messsage and link of user not subscribed"
    );
    assert.equal(
      find(".wizard-subscription-container").length,
      1,
      "Wizard subscription features are not accesible"
    );
    await click(".step .link-list button");
    const stepOneText = "step_1 (step_1)";
    const stepOneBtn = find(`.step button:contains(${stepOneText})`);
    assert.equal(stepOneBtn.length, 1, "Creating a step");
    const stepTitle = "step title";
    await fillIn(".wizard-custom-step input[name='title']", stepTitle);
    const stepButtonText = $.trim(
      $(".step div[data-id='step_1'] button").text()
    );
    assert.ok(
      stepButtonText.includes(stepTitle),
      "The step button changes according to title"
    );
    assert.equal(
      find(".wizard-subscription-container").length,
      2,
      "Steps subscription features are not accesible"
    );
    await click(".field .link-list button");
    assert.ok(
      !visible(".wizard-custom-field button.undo-changes"),
      "clear button is not rendered"
    );
    const fieldOneText = "step_1_field_1 (step_1_field_1)";
    const fieldOneBtn = find(`.field button:contains(${fieldOneText})`);
    assert.equal(fieldOneBtn.length, 1, "Creating a field");
    const fieldTitle = "field title";
    await fillIn(".wizard-custom-field input[name='label']", fieldTitle);
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
    await click(`.wizard-custom-field button.undo-changes`);
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
    assert.ok(
      query(".wizard-custom-field .message-content").innerText.includes(
        "You're editing a field"
      ),
      "Text tipe for field correctly selected"
    );
    assert.equal(
      find(".wizard-subscription-container").length,
      3,
      "Field subscription features are not accesible"
    );
    await click(".action .link-list button");
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
    const listEnabled = findAll(
      ".wizard-custom-action .setting .setting-value ul li:not(.disabled)"
    );
    const listDisabled = findAll(
      ".wizard-custom-action .setting .setting-value ul li.disabled"
    );
    assert.ok(
      listDisabled.length === 7,
      "disabled items displayed correctly in action dropdown"
    );
    assert.ok(
      listEnabled.length === 4,
      "Enabled items displayed correctly in action dropdown"
    );
    await actionTypeDropdown.selectRowByValue("create_topic");
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
    await actionTypeDropdown.selectRowByValue("open_composer");
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 8,
      "Display all settings of open composer"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("update_profile");
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 4,
      "Display all settings of update profile"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("route_to");
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 4,
      "Display all settings of route to"
    );
    await actionTypeDropdown.expand();
    await click('[data-name="Select a type"]');
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 2,
      "the settings options is empty when no action is selected"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("create_topic");
    assert.ok(
      !visible('.admin-wizard-buttons button:contains("Delete Wizard")'),
      "delete wizard button not displayed"
    );
    await click(".admin-wizard-buttons button");
    assert.equal(
      currentURL(),
      "/admin/wizards/wizard/new_wizard_for_testing",
      "clicking the button navigates to the correct URL"
    );
    assert.ok(
      visible('.admin-wizard-buttons button:contains("Delete Wizard")'),
      "delete wizard button visible"
    );
  });
});
