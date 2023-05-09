import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { findAll, visit } from "@ember/test-helpers";
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
});
