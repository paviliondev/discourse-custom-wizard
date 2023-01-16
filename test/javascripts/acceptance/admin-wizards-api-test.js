import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
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
    server.put("/admin/wizards/api/new_api", () => {
      return helper.response({
        success: "OK",
        name: "new_api",
      });
    });
  });

  test("Visit API tab", async (assert) => {
    await visit("/admin/wizards/api");
    const list = find(".admin-controls li");
    const count = list.length;
    assert.equal(count, 6, "There should be 6 admin tabs");
    // create new api
    await click('button:contains("Create API")');
    assert.ok(
      query(".wizard-header.large").innerText.includes("New API"),
      "it displays API creation message"
    );
    // fill data
    await fillIn('.metadata input[placeholder="Display name"]', "new API");
    await fillIn('.metadata input[placeholder="Underscored"]', "new_api");
    const fieldTypeDropdown = selectKit(
      ".wizard-api-authentication .settings .control-group.auth-type .select-kit"
    );
    await fieldTypeDropdown.expand();
    await fieldTypeDropdown.selectRowByValue("basic");
    await fillIn(
      ".wizard-api-authentication .settings .control-group:eq(1) .controls input",
      "some_username"
    );
    await fillIn(
      ".wizard-api-authentication .settings .control-group:eq(2) .controls input",
      "some_password"
    );
    await click('.wizard-api-endpoints button:contains("Add endpoint")');
    await fillIn(
      '.wizard-api-endpoints .endpoint .top input[placeholder="Endpoint name"]',
      "endpoint_name"
    );
    await fillIn(
      '.wizard-api-endpoints .endpoint .top input[placeholder="Enter a url"]',
      "https://test.api.com"
    );
    let endpointMethodDropdown = await selectKit(
      '.wizard-api-endpoints .endpoint .bottom details:has(summary[name="Filter by: Select a method"])'
    );
    await endpointMethodDropdown.expand();
    await endpointMethodDropdown.selectRowByValue("POST");

    // let successCodesDropdown = await selectKit(
    //   ".wizard-api-endpoints .endpoint .bottom .select-kit .multi-select"
    // );
    // await successCodesDropdown.expand();
    // await successCodesDropdown.selectRowByValue("200");
    pauseTest();
    // let contentTypeDropdown = await selectKit(
    //   '.wizard-api-endpoints .endpoint .bottom details:has(summary[name="Filter by: Select a content type"])'
    // );
    // await contentTypeDropdown.expand();
    // await contentTypeDropdown.selectRowByValue("application/JSON");

    // const contentTypeDropdown = selectKit(
    //   ".wizard-api-endpoints .endpoint .bottom details"
    // );
    // await contentTypeDropdown.expand();
    // await contentTypeDropdown.selectRowByValue("application/JSON");
    // send a request
  });
});
