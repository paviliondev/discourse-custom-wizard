import {
  acceptance,
  query,
  visible,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { findAll, visit } from "@ember/test-helpers";
import {
  getCustomFields,
  getUnsubscribedAdminWizards,
  getWizard,
} from "../helpers/admin-wizard";

acceptance("Admin | Custom Fields", function (needs) {
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

  test("viewing custom fields tab", async (assert) => {
    await visit("/admin/wizards/custom-fields");
    assert.ok(find("table"));
    assert.ok(findAll("table tbody tr").length === 9);
    assert.ok(
      query(".message-content").innerText.includes(
        "View, create, edit and destroy custom fields"
      ),
      "it displays wizard message"
    );
    await click(".btn-icon-text");
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
  });
});
