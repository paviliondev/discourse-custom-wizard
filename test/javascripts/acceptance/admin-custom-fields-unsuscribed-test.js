import {
  acceptance,
  query,
  visible,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, findAll, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  getCustomFields,
  getUnsubscribedAdminWizards,
  getWizard,
} from "../helpers/admin-wizard";

acceptance("Admin | Custom Fields Unsuscribed", function (needs) {
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
  });

  test("Navigate to custom fields tab", async (assert) => {
    await visit("/admin/wizards/custom-fields");
    assert.ok(find("table"));
    assert.ok(findAll("table tbody tr").length === 9);
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
});
