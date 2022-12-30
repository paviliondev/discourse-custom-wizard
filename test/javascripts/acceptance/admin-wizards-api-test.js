import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";
import {
  getBusinessAdminWizard,
  getCustomFields,
  getWizard,
} from "../helpers/admin-wizard";

acceptance("Admin | API tab", function (needs) {
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
      return helper.response(getBusinessAdminWizard);
    });
    server.get("/admin/wizards/custom-fields", () => {
      return helper.response(getCustomFields);
    });
    server.get("/admin/wizards/api", () => {
      return helper.response([]);
    });
    server.get("/admin/customize/user_fields", () => {
      return helper.response({ user_fields: [] });
    });
    server.put("/admin/wizards/api/gresgres", () => {
      return helper.response({
        success: "OK",
        name: "gresgres",
      });
    });
  });

  test("Visit API tab", async (assert) => {
    await visit("/admin/wizards/api");
    const list = find(".admin-controls li");
    const count = list.length;
    assert.equal(count, 6, "There should be 6 admin tabs");
  });
});
