import {
  acceptance,
  query,
  visible,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, fillIn, findAll, visit, waitUntil } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  getCustomFields,
  getUnsubscribedAdminWizards,
  getWizard,
} from "../helpers/admin-wizard";
import { Promise } from "rsvp";

acceptance("Admin | Custom Fields Unsubscribed", function (needs) {
  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });

  needs.pretender((server, helper) => {
    server.get("/admin/wizards/wizard", () => {
      return helper.response(getWizard);
    });
    server.get("/admin/wizards", () => {
      return helper.response(getUnsubscribedAdminWizards);
    });
    server.get("/admin/wizards/custom-fields", () => {
      return helper.response(getCustomFields);
    });
    server.put("/admin/wizards/custom-fields", () => {
      return helper.response({ success: "OK" });
    });
    server.delete("/admin/wizards/custom-fields/topic_custom_field", () => {
      return helper.response({ success: "OK" });
    });
  });

  async function selectTypeAndSerializerAndFillInName(
    type,
    serializer,
    name,
    summaryName
  ) {
    const typeDropdown = selectKit(
      `.admin-wizard-container details:has(summary[name="${summaryName}"])`
    );
    await typeDropdown.expand();
    await click(
      `.select-kit-collection li[data-value="${type.toLowerCase()}"]`
    );

    const serializerDropdown = selectKit(
      ".admin-wizard-container details.multi-select"
    );
    await serializerDropdown.expand();
    await click(
      `.select-kit-collection li[data-value="${serializer
        .toLowerCase()
        .replace(/ /g, "_")}"]`
    );

    await fillIn(
      ".admin-wizard-container input",
      name.toLowerCase().replace(/ /g, "_")
    );
  }

  async function waitForSaveMessage() {
    // Wait for the "Saved custom field" message to appear
    await waitUntil(
      () =>
        document.querySelector(".message-content")?.innerText ===
        "Saved custom field",
      { timeout: 5000 }
    );

    // Wait for the message to change back to the original text
    await waitUntil(
      () =>
        document.querySelector(".message-content")?.innerText ===
        "View, create, edit and destroy custom fields",
      { timeout: 15000 }
    );
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  test("Navigate to custom fields tab", async (assert) => {
    await visit("/admin/wizards/custom-fields");
    assert.ok(find("table"));
    assert.ok(
      findAll("table tbody tr").length === 4,
      "Display loaded custom fields"
    );
    assert.ok(
      query(".message-content").innerText.includes(
        "View, create, edit and destroy custom fields"
      ),
      "it displays wizard message"
    );
  });
  test("view available custom fields for unsubscribed plan", async (assert) => {
    await visit("/admin/wizards/custom-fields");
    await click(".admin-wizard-controls .btn-icon-text");
    assert.ok(
      visible(".wizard-subscription-selector"),
      "custom field class is present"
    );
    assert.ok(
      visible(".wizard-subscription-selector-header"),
      "custom field type is present"
    );
    assert.ok(visible(".input"), "custom field name is present");
    assert.ok(visible(".multi-select"), "custom field serializer is present");
    assert.ok(visible(".actions"), "custom field action buttons are present");

    const dropdown1 = selectKit(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a class"])'
    );
    await dropdown1.expand();
    let enabledOptions1 = findAll(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a class"]) ul li:not(.disabled)'
    );
    let disabledOptions1 = findAll(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a class"]) ul li.disabled'
    );
    assert.equal(
      enabledOptions1.length,
      2,
      "There are two enabled options for class fields"
    );
    assert.equal(
      disabledOptions1.length,
      2,
      "There are two disabled options for class fields"
    );
    const dropdown2 = selectKit(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a type"])'
    );
    await dropdown2.expand();
    let enabledOptions2 = findAll(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a type"]) ul li:not(.disabled)'
    );
    let disabledOptions2 = findAll(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a type"]) ul li.disabled'
    );
    assert.equal(
      enabledOptions2.length,
      3,
      "There are three enabled options for type"
    );
    assert.equal(
      disabledOptions2.length,
      1,
      "There is one disabled option for type"
    );
  });
  test("change custom fields for unsubscribed plan", async (assert) => {
    await visit("/admin/wizards/custom-fields");
    await click(".admin-wizard-controls .btn-icon-text");

    const dropdown1 = selectKit(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a class"])'
    );
    await dropdown1.expand();
    await click('.select-kit-collection li[data-value="topic"]');
    const serializerDropdown = selectKit(
      ".admin-wizard-container details.multi-select"
    );
    await serializerDropdown.expand();
    let enabledOptions1 = findAll(
      ".admin-wizard-container details.multi-select ul li"
    );
    assert.equal(
      enabledOptions1.length,
      2,
      "There are two enabled options in the serializer dropdown for Topic"
    );
    await serializerDropdown.collapse();
    const dropdown2 = selectKit(
      '.admin-wizard-container details:has(summary[name="Filter by: Topic"])'
    );
    await dropdown2.expand();
    await click('.select-kit-collection li[data-value="post"]');
    await serializerDropdown.expand();
    let enabledOptions2 = findAll(
      ".admin-wizard-container details.multi-select ul li"
    );
    assert.equal(
      enabledOptions2.length,
      1,
      "There is one enabled option in the serializer dropdown for Post"
    );
  });

  test("Create Topic and Post custom fields", async (assert) => {
    await visit("/admin/wizards/custom-fields");
    assert.ok(
      findAll("table tbody tr").length === 4,
      "Display loaded custom fields"
    );
    await click(".admin-wizard-controls .btn-icon-text");

    const dropdownTopic = selectKit(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a class"])'
    );
    await dropdownTopic.expand();
    await click('.select-kit-collection li[data-value="topic"]');

    await selectTypeAndSerializerAndFillInName(
      "String",
      "Topic View",
      "Topic Custom Field",
      "Filter by: Select a type"
    );

    await click(".actions .save");
    // Wait for the "Saved custom field" message to appear
    await waitForSaveMessage();
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(1) label"
      ).innerText.includes("topic"),
      "Topic custom field is displayed"
    );
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(3) label"
      ).innerText.includes("topic_custom_field"),
      "Topic custom field name is displayed"
    );

    await click(".admin-wizard-controls .btn-icon-text");

    const dropdownPost = selectKit(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a class"])'
    );
    await dropdownPost.expand();
    await click('.select-kit-collection li[data-value="post"]');

    await selectTypeAndSerializerAndFillInName(
      "Boolean",
      "Post",
      "Post Custom Field",
      "Filter by: Select a type"
    );

    await click(".actions .save");
    // Wait for the "Saved custom field" message to appear
    await waitForSaveMessage();
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(1) label"
      ).innerText.includes("post"),
      "Post custom field is displayed"
    );
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(3) label"
      ).innerText.includes("post_custom_field"),
      "Post custom field name is displayed"
    );
    assert.ok(
      findAll("table tbody tr").length === 6,
      "Display added custom fields"
    );
  });
  test("Update Topic custom field", async (assert) => {
    await visit("/admin/wizards/custom-fields");
    await click(".admin-wizard-controls .btn-icon-text");
    const dropdownTopic = selectKit(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a class"])'
    );
    await dropdownTopic.expand();
    await click('.select-kit-collection li[data-value="topic"]');
    await selectTypeAndSerializerAndFillInName(
      "String",
      "Topic View",
      "Topic Custom Field",
      "Filter by: Select a type"
    );
    await click(".actions .save");
    await waitForSaveMessage();
    await click(".admin-wizard-container tbody tr:first-child button");
    await selectTypeAndSerializerAndFillInName(
      "Boolean",
      "Topic List Item",
      "Updated Topic Custom Field",
      "Filter by: String"
    );
    await click(".admin-wizard-container tbody tr:first-child .save");
    await waitForSaveMessage();
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(1) label"
      ).innerText.includes("topic"),
      "Topic custom field is displayed"
    );
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(2) label"
      ).innerText.includes("boolean"),
      "Updated Type is displayed"
    );
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(3) label"
      ).innerText.includes("updated_topic_custom_field"),
      "Updated Topic custom field name is displayed"
    );
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(4)"
      ).innerText.includes("topic_view"),
      "Original Serializer is displayed"
    );
    assert.ok(
      query(
        ".admin-wizard-container tbody tr:first-child td:nth-child(4)"
      ).innerText.includes("topic_list_item"),
      "Updated Serializer is displayed"
    );
  });
  test("Delete Topic custom field", async (assert) => {
    await visit("/admin/wizards/custom-fields");
    assert.ok(
      findAll("table tbody tr").length === 4,
      "Display loaded custom fields"
    );
    await click(".admin-wizard-controls .btn-icon-text");

    const dropdownTopic = selectKit(
      '.admin-wizard-container details:has(summary[name="Filter by: Select a class"])'
    );
    await dropdownTopic.expand();
    await click('.select-kit-collection li[data-value="topic"]');
    await selectTypeAndSerializerAndFillInName(
      "String",
      "Topic View",
      "Topic Custom Field",
      "Filter by: Select a type"
    );
    await click(".actions .save");
    await waitForSaveMessage();
    assert.ok(
      findAll("table tbody tr").length === 5,
      "Display added custom fields"
    );
    await click(".admin-wizard-container tbody tr:first-child button");
    await click(".actions .destroy");
    assert.ok(
      findAll("table tbody tr").length === 4,
      "Display custom fields without deleted fields"
    );
  });
});
