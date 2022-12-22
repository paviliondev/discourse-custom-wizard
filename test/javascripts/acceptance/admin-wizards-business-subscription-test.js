import {
  acceptance,
  query,
  visible,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { findAll, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  getAdminTestingWizard,
  getBusinessAdminWizard,
  getCreatedWizard,
  getCustomFields,
  getWizard,
} from "../helpers/admin-wizard";

acceptance("Admin | Custom Wizard Business Subscription", function (needs) {
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
      return helper.response(getBusinessAdminWizard);
    });
    server.get("/admin/wizards/api", () => {
      return helper.response([]);
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

  test("creting a new wizard", async (assert) => {
    await visit("/admin/wizards/wizard");
    await click('button:contains("Create Wizard")');
    assert.ok(
      query(".message-content").innerText.includes(
        "You're creating a new wizard"
      ),
      "it displays wizard creation message"
    );
    assert.step("Step 1: Inserting a title");
    const wizardTitle = "New wizard for testing";
    await fillIn(".wizard-header input", wizardTitle);
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
    assert.ok(subsFeature.is(":checked"), "subscription feature available");
    assert.step("Step 2: Creating a step section");
    const stepAddBtn = find(".step .link-list button:contains('Add')");
    await click(stepAddBtn);
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
      find(".wizard-subscription-container a:contains('Subscribed')").length,
      2,
      "Steps subscription features are accesible"
    );
    assert.step("Step 3: Creating a field section");
    const fieldAddBtn = find(".field .link-list button:contains('Add')");
    await click(fieldAddBtn);
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
    const clearBtn = find(`.wizard-custom-field button.undo-changes`);
    await click(clearBtn);
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
      find(".wizard-subscription-container a:contains('Subscribed')").length,
      3,
      "Field subscription features are accesible"
    );
    // creating action content
    assert.step("Step 4: Creating a action section");

    const actionAddBtn = find(".action .link-list button:contains('Add')");
    await click(actionAddBtn);
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
      listDisabled.length === 0,
      "Disabled items displayed correctly in action dropdown"
    );
    assert.ok(
      listEnabled.length === 10,
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
    await actionTypeDropdown.selectRowByValue("send_to_api");
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 5,
      "Display all settings of send to api"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("create_category");
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 9,
      "Display all settings of create categories"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("create_group");
    listTopicSettings = findAll(
      ".admin-wizard-container .wizard-custom-action .setting"
    );
    assert.ok(
      listTopicSettings.length === 14,
      "Display all settings of create group"
    );
    await actionTypeDropdown.expand();
    await actionTypeDropdown.selectRowByValue("create_topic");
    assert.step("Step 5: Save wizard");
    const saveButton = find(
      '.admin-wizard-buttons button:contains("Save Changes")'
    );
    assert.ok(
      !visible('.admin-wizard-buttons button:contains("Delete Wizard")'),
      "delete wizard button not displayed"
    );
    await click(saveButton);
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
