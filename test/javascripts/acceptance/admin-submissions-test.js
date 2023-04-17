import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, findAll, visit } from "@ember/test-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  getUnsubscribedAdminWizards,
  getWizard,
  getWizardSubmissions,
} from "../helpers/admin-wizard";

acceptance("Admin | Submissions", function (needs) {
  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });
  needs.pretender((server, helper) => {
    server.get("/admin/wizards/submissions", () => {
      return helper.response([
        { id: "this_is_testing_wizard", name: "This is testing wizard" },
      ]);
    });
    server.get("/admin/wizards/submissions/this_is_testing_wizard", () => {
      return helper.response(getWizardSubmissions);
    });
    server.get("/admin/wizards", () => {
      return helper.response(getUnsubscribedAdminWizards);
    });
    server.get("/admin/wizards/wizard", () => {
      return helper.response(getWizard);
    });
  });
  test("viewing submissions fields tab", async (assert) => {
    await visit("/admin/wizards/submissions");
    const wizards = selectKit(".select-kit");
    assert.ok(
      query(".message-content").innerText.includes(
        "Select a wizard to see its submissions"
      ),
      "it displays submissions message"
    );
    assert.ok(
      query(".message-content").innerText.includes("Select a wizard"),
      "it displays list of wizards"
    );
    await wizards.expand();
    await wizards.selectRowByValue("this_is_testing_wizard");
    assert.ok(
      query(".message-content").innerText.includes(
        "You're viewing the submissions of the This is testing wizard"
      ),
      "it displays submissions for a selected wizard"
    );
    assert.ok(find("table"));
    assert.ok(
      findAll("table tbody tr").length >= 1,
      "Displays submissions list"
    );

    await wizards.expand();
    await click('[data-name="Select a wizard"]');
    const wizardContainerDiv = find(".admin-wizard-container");
    assert.ok(wizardContainerDiv.children().length === 0, "the div is empty");
  });
});
