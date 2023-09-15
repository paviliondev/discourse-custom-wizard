import {
  acceptance,
  exists,
  query,
  visible,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, currentURL, fillIn, findAll, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  getAdminTestingWizard,
  getCreatedWizard,
  getCustomFields,
  getUniqueWizard,
  getUnsubscribedAdminWizards,
  getWizard,
} from "../helpers/admin-wizard";

acceptance("Admin | Custom Wizard Unsubscribed", function (needs) {
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
    server.get("/admin/wizards/wizard/unique_wizard", () => {
      return helper.response(getUniqueWizard);
    });
  });

  async function appendText(selector, text) {
    let element = document.querySelector(selector);
    if (element) {
      let currentValue = element.value;
      let newValue = currentValue + text;
      await fillIn(selector, newValue);
    }
  }

  test("Displaying all tabs except API", async (assert) => {
    await visit("/admin/wizards");
    const list = find(".admin-controls li");
    const count = list.length;
    assert.equal(count, 5, "There should be 5 admin tabs");
  });

  test("creating a new wizard", async (assert) => {
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
    await click(".btn-after-time");
    assert.ok(
      exists(".d-date-time-input .d-time-input span.name"),
      "a time selector is shown"
    );
    let timeText = query(
      ".d-date-time-input .d-time-input span.name"
    ).innerText;
    const regex = /\d\d\:\d\d/;
    assert.ok(regex.test(timeText));
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
    await appendText(
      ".wizard-custom-step .wizard-text-editor textarea",
      "Input in step description composer"
    );
    await click(".wizard-custom-step .wizard-editor-gutter button:first-child");
    assert.strictEqual(
      query(
        ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper p"
      ).textContent.trim(),
      "Input in step description composer"
    );
    await appendText(
      ".wizard-custom-step .wizard-text-editor textarea",
      "\n\n**Bold text**"
    );
    let boldText = await query(
      ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper strong"
    ).innerHTML.trim();
    assert.strictEqual(
      boldText,
      "Bold text",
      "The bold text in the preview wrapper should be 'Bold Text'"
    );
    await appendText(
      ".wizard-custom-step .wizard-text-editor textarea",
      "\n\n*emphasized text*"
    );
    let empText = await query(
      ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper em"
    ).innerHTML.trim();
    assert.strictEqual(
      empText,
      "emphasized text",
      "The emphasized text in the preview wrapper should be 'emphasized text'"
    );
    await appendText(
      ".wizard-custom-step .wizard-text-editor textarea",
      "\n\n> Blockqoute text"
    );
    let blockquoteText = await query(
      ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper blockquote p"
    ).innerHTML.trim();
    assert.strictEqual(
      blockquoteText,
      "Blockqoute text",
      "The emphasized text in the preview wrapper should be 'Blockqoute text'"
    );
    await appendText(
      ".wizard-custom-step .wizard-text-editor textarea",
      `\n\n\`\`\`
                              \code text
                              \n\`\`\``
    );
    let codeText = await query(
      ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper code"
    ).innerHTML.trim();
    assert.strictEqual(
      codeText,
      "code text",
      "The emphasized text in the preview wrapper should be 'code text'"
    );
    await appendText(
      ".wizard-custom-step .wizard-text-editor textarea",
      `\n\n* List item\n* List item`
    );
    let listItems = findAll(
      ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper ul li"
    );
    assert.strictEqual(
      listItems.length,
      2,
      "There should be two list items in the unordered list in the preview wrapper"
    );
    assert.strictEqual(
      listItems[0].textContent.trim(),
      "List item",
      "The first list item should be 'List item'"
    );
    assert.strictEqual(
      listItems[1].textContent.trim(),
      "List item",
      "The second list item should be 'List item'"
    );
    await appendText(
      ".wizard-custom-step .wizard-text-editor textarea",
      `\n\n1. List item\n1. List item`
    );
    let orderedListItems = findAll(
      ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper ol li"
    );
    assert.strictEqual(
      orderedListItems.length,
      2,
      "There should be two list items in the ordered list in the preview wrapper"
    );
    assert.strictEqual(
      orderedListItems[0].textContent.trim(),
      "List item",
      "The first list item should be 'List item'"
    );
    assert.strictEqual(
      orderedListItems[1].textContent.trim(),
      "List item",
      "The second list item should be 'List item'"
    );
    await appendText(
      ".wizard-custom-step .wizard-text-editor textarea",
      `\n\n`
    );
    await click(
      ".wizard-custom-step .wizard-text-editor .d-editor button.link"
    );
    assert.ok(exists(".insert-link.modal-body"), "hyperlink modal visible");

    await fillIn(".modal-body .link-url", "google.com");
    await fillIn(".modal-body .link-text", "Google");
    await click(".modal-footer button.btn-primary");
    let urlText = await query(
      ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper a"
    ).innerHTML.trim();
    assert.strictEqual(
      urlText,
      "Google",
      "The link text in the preview wrapper should be 'Google'"
    );
    await click(
      ".wizard-custom-step .wizard-text-editor .d-editor button.local-dates"
    );
    assert.ok(
      exists(".discourse-local-dates-create-modal .modal-body"),
      "Insert date-time modal visible"
    );
    assert.ok(
      !exists(
        ".discourse-local-dates-create-modal.modal-body .advanced-options"
      ),
      "Advanced mode not visible"
    );
    await click(".modal-footer button.advanced-mode-btn");
    assert.ok(
      exists(
        ".discourse-local-dates-create-modal .modal-body .advanced-options"
      ),
      "Advanced mode is visible"
    );
    await click(".modal-footer button.btn-primary");
    assert.ok(
      exists(
        ".wizard-custom-step .wizard-text-editor .d-editor-preview-wrapper span.discourse-local-date"
      ),
      "Date inserted"
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
    await fillIn(
      ".wizard-custom-field textarea[name='description']",
      "First step field description"
    );
    await click(`.wizard-custom-field button.undo-changes`);
    fieldButtonText = $(".field div[data-id='step_1_field_1'] button")
      .text()
      .trim();
    assert.ok(
      fieldButtonText.includes("step_1_field_1 (step_1_field_1)"),
      "The field button changes to default title after clear button is clicked"
    );
    await fillIn(".wizard-custom-field input[name='label']", fieldTitle);
    await fillIn(
      ".wizard-custom-field textarea[name='description']",
      "First step field description"
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
    const fieldsContentIf = [4, 8];
    for (let i = 0; i < fieldsContentIf.length; i++) {
      await click(
        `.admin-wizard-container .wizard-custom-action .setting:nth-of-type(${fieldsContentIf[i]}) button`
      );
      let selectKitInsideThirdSetting = await selectKit(
        `.admin-wizard-container .wizard-custom-action .setting:nth-of-type(${fieldsContentIf[i]}) .select-kit`
      );
      await selectKitInsideThirdSetting.expand();
      await selectKitInsideThirdSetting.selectRowByIndex(1);
      await fillIn(
        `.admin-wizard-container .wizard-custom-action .setting:nth-of-type(${fieldsContentIf[i]}) .key input`,
        "Action title"
      );
      await fillIn(
        `.admin-wizard-container .wizard-custom-action .setting:nth-of-type(${fieldsContentIf[i]}) .value input`,
        "Some value"
      );
      await fillIn(
        `.admin-wizard-container .wizard-custom-action .setting:nth-of-type(${fieldsContentIf[i]}) .output input`,
        "Result text"
      );
      const actualTitle = query(
        `.admin-wizard-container .wizard-custom-action .setting:nth-of-type(${fieldsContentIf[i]}) .key input`
      ).value;
      const actualValue = query(
        `.admin-wizard-container .wizard-custom-action .setting:nth-of-type(${fieldsContentIf[i]}) .value input`
      ).value;
      const actualResultText = query(
        `.admin-wizard-container .wizard-custom-action .setting:nth-of-type(${fieldsContentIf[i]}) .output input`
      ).value;

      assert.strictEqual(actualTitle, "Action title", "Title is correct");
      assert.strictEqual(actualValue, "Some value", "Value is correct");
      assert.strictEqual(actualResultText, "Result text", "Text is correct");
    }
    assert.ok(
      !visible('.admin-wizard-buttons button:contains("Delete Wizard")'),
      "delete wizard button not displayed"
    );
    await click(".admin-wizard-buttons button");
    assert.equal(
      currentURL(),
      "/admin/wizards/wizard/new_wizard_for_testing",
      "Wizard saved successfully"
    );
    assert.ok(
      visible('.admin-wizard-buttons button:contains("Delete Wizard")'),
      "delete wizard button visible"
    );
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

    await wizards.selectRowByValue("unique_wizard");
    assert.ok(
      query(".message-content").innerText.includes("You're editing a wizard"),
      "it displays wizard message for a selected wizard"
    );
    assert.equal(
      query(".admin-wizard-container .wizard-header input").value,
      getUniqueWizard.name,
      "The wizard name is correctly displayed"
    );
    // Save wizard Submissions
    assert.equal(
      query(".wizard-settings .setting:nth-of-type(1) input").checked,
      getUniqueWizard.save_submissions,
      "The save submissions flag is correctly set"
    );

    // Multiple Submissions
    assert.equal(
      query(".wizard-settings .setting:nth-of-type(2) input").checked,
      getUniqueWizard.multiple_submissions,
      "The multiple submissions flag is correctly set"
    );

    // After Signup
    assert.equal(
      query(".wizard-settings .setting:nth-of-type(3) input").checked,
      getUniqueWizard.after_signup,
      "The after signup flag is correctly set"
    );

    // Prompt Completion
    assert.equal(
      query(".wizard-settings .setting:nth-of-type(4) input").checked,
      getUniqueWizard.prompt_completion,
      "The prompt completion flag is correctly set"
    );
    // step content
    for (let i = 0; i < getUniqueWizard.steps.length; i++) {
      // click on the step that is needed
      await click(
        `.wizard-links.step .link-list div:nth-of-type(${
          i + 1
        }) button.btn-text`
      );
      assert.equal(
        query(".wizard-custom-step  input[name='title']").value,
        getUniqueWizard.steps[i].title,
        "Step title is correct"
      );
      assert.equal(
        query(".wizard-custom-step .wizard-text-editor textarea").value,
        getUniqueWizard.steps[i].description,
        "Step description is correct"
      );
      // field content
      for (let j = 0; j < getUniqueWizard.steps[i].fields.length; j++) {
        await click(
          `.wizard-links.field .link-list div:nth-of-type(${
            j + 1
          }) button.btn-text`
        );
        assert.equal(
          query(".wizard-custom-field.visible .setting:nth-of-type(1) input")
            .value,
          getUniqueWizard.steps[i].fields[j].label,
          "Field title is correct"
        );
        assert.equal(
          query(".wizard-custom-field.visible .setting:nth-of-type(3) textarea")
            .value,
          getUniqueWizard.steps[i].fields[j].description,
          "Field description is correct"
        );
        let selectTypeElement = document.querySelector(
          `.admin-wizard-container .wizard-custom-field.visible .setting:nth-of-type(5) .select-kit`
        );
        let summaryElement = selectTypeElement.querySelector("summary");
        assert.equal(
          summaryElement.getAttribute("data-value"),
          getUniqueWizard.steps[i].fields[j].type,
          "The correct data-value is selected"
        );
      }
    }
  });
});
