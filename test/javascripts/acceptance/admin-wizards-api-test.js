import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, select, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  getBusinessAdminWizard,
  getCustomFields,
  getNewApi,
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
      return helper.response([
        {
          name: "new_api",
          title: "new API",
          endpoints: [{ id: "59e3b6", name: "ag" }],
        },
      ]);
    });
    server.get("/admin/customize/user_fields", () => {
      return helper.response({ user_fields: [] });
    });
    server.put("/admin/wizards/api/new_api", () => {
      return helper.response({
        success: "OK",
        api: {
          name: "new_api",
          title: "new API",
          authorization: {
            auth_type: "basic",
            auth_url: null,
            token_url: null,
            client_id: null,
            client_secret: null,
            authorized: null,
            auth_params: [],
            access_token: null,
            refresh_token: null,
            token_expires_at: null,
            token_refresh_at: null,
            code: null,
            username: "some_username",
            password: "some_password",
          },
          endpoints: [
            {
              id: "8371de",
              name: "endpoint_name",
              method: "POST",
              url: "https://test.api.com",
              content_type: "application/json",
              success_codes: [200, 100],
            },
          ],
          log: [],
        },
      });
    });
    server.get("/admin/wizards/api/new_api", () => {
      return helper.response({
        name: "new_api",
        title: "new API",
        authorization: {
          auth_type: "basic",
          auth_url: null,
          token_url: null,
          client_id: null,
          client_secret: null,
          authorized: null,
          auth_params: [],
          access_token: null,
          refresh_token: null,
          token_expires_at: null,
          token_refresh_at: null,
          code: null,
          username: "some_username",
          password: "some_password",
        },
        endpoints: [
          {
            id: "8371de",
            name: "endpoint_name",
            method: "POST",
            url: "https://test.api.com",
            content_type: "application/json",
            success_codes: [200, 100],
          },
        ],
        log: [],
      });
    });
  });

  test("Visit API tab", async function (assert) {
    await visit("/admin/wizards/api");
    const list = find(".admin-controls li");
    const count = list.length;
    assert.equal(count, 6, "There should be 6 admin tabs");

    // create new api
    await click(".admin-wizard-controls button");
    assert.ok(
      query(".wizard-header.large").innerText.includes("New API"),
      "it displays API creation message"
    );
    assert.equal(
      currentURL(),
      "/admin/wizards/api/create",
      "clicking the button navigates to the correct URL"
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
    await click(".wizard-api-endpoints button");
    await fillIn(
      '.wizard-api-endpoints .endpoint .top input[placeholder="Endpoint name"]',
      "endpoint_name"
    );
    await fillIn(
      '.wizard-api-endpoints .endpoint .top input[placeholder="Enter a url"]',
      "https://test.api.com"
    );
    const endpointMethodDropdown = await selectKit(
      '.wizard-api-endpoints .endpoint .bottom details:has(summary[name="Filter by: Select a method"])'
    );
    await endpointMethodDropdown.expand();
    await endpointMethodDropdown.selectRowByValue("POST");

    const contentTypeDropdown = await selectKit(
      '.wizard-api-endpoints .endpoint .bottom details:has(summary[name="Filter by: Select a content type"])'
    );
    await contentTypeDropdown.expand();
    await contentTypeDropdown.selectRowByValue("application/json");

    const successCodesDropdown = await selectKit(
      ".wizard-api-endpoints .endpoint .bottom details.multi-select"
    );
    await successCodesDropdown.expand();
    await successCodesDropdown.selectRowByValue(200);
    await successCodesDropdown.selectRowByValue(100);

    assert.strictEqual(
      successCodesDropdown.header().value(),
      "200,100",
      "group should be set"
    );
    await click(".wizard-api-header.page button.btn-primary");
    assert.equal(
      currentURL(),
      "/admin/wizards/api/new_api",
      "clicking the button navigates to the correct URL"
    );
  });
});
