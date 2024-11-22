import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  query,
  queryAll,
} from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  getAnotherWizardSubmission,
  getSuppliers,
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
        { id: "another_wizard", name: "another wizard" },
      ]);
    });
    server.get("/admin/wizards/submissions/this_is_testing_wizard", () => {
      return helper.response(getWizardSubmissions);
    });
    server.get("/admin/wizards/submissions/another_wizard", () => {
      return helper.response(getAnotherWizardSubmission);
    });
    server.get("/admin/wizards/subscription", () => {
      return helper.response(getUnsubscribedAdminWizards);
    });
    server.get("/admin/wizards/wizard", () => {
      return helper.response(getWizard);
    });
    server.get("/admin/plugins/subscription-client/suppliers", () => {
      return helper.response(getSuppliers);
    });
  });
  test("View submissions fields tab and content", async (assert) => {
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
    const submissions = getWizardSubmissions.submissions; // Get submissions data from your JSON file
    const rows = queryAll("table tbody tr");

    for (let i = 0; i < submissions.length; i++) {
      const dateCell = rows[i].querySelector("td:nth-child(1)");
      const userCell = rows[i].querySelector("td:nth-child(2)");
      const stepCell = rows[i].querySelector("td:nth-child(3)");
      const expectedDate = moment(submissions[i].submitted_at).format(
        "MMM D, YYYY h:mm a"
      );

      assert.equal(
        dateCell.innerText,
        expectedDate,
        `Date is displayed correctly for submission ${i + 1}`
      );
      assert.equal(
        userCell.innerText.trim(),
        submissions[i].user.username,
        `User is displayed correctly for submission ${i + 1}`
      );
      assert.equal(
        stepCell.innerText.trim().split("\n")[0],
        submissions[i].fields.step_1_field_1.value,
        `Step is displayed correctly for submission ${i + 1}`
      );
    }
    assert.ok(
      queryAll("table tbody tr").length >= 1,
      "Displays submissions list"
    );

    await wizards.expand();
    await click('[data-name="Select a wizard"]');
    const wizardContainerDiv = query(".admin-wizard-container");
    assert.ok(wizardContainerDiv.children.length === 0, "the div is empty");
  });
  test("View submissions tab for another wizard with more steps", async (assert) => {
    await visit("/admin/wizards/submissions");
    const wizards = selectKit(".select-kit");

    await wizards.expand();
    await wizards.selectRowByValue("another_wizard");

    assert.ok(
      query(".message-content").innerText.includes(
        "You're viewing the submissions of the another wizard"
      ),
      "it displays submissions for another wizard"
    );

    const submissions = getAnotherWizardSubmission.submissions; // Get submissions data from your JSON file
    const rows = queryAll("table tbody tr");

    for (let i = 0; i < submissions.length; i++) {
      const dateCell = rows[i].querySelector("td:nth-child(1)");
      const userCell = rows[i].querySelector("td:nth-child(2)");
      const step1Cell = rows[i].querySelector("td:nth-child(3)");
      const step2Cell = rows[i].querySelector("td:nth-child(4)");
      const submission = submissions[i];
      const expectedDate = moment(submission.submitted_at).format(
        "MMM D, YYYY h:mm a"
      );

      assert.equal(
        dateCell.innerText,
        expectedDate,
        `Date is displayed correctly for submission ${i + 1}`
      );
      assert.equal(
        userCell.innerText.trim(),
        submissions[i].user.username,
        `User is displayed correctly for submission ${i + 1}`
      );
      assert.equal(
        step1Cell.innerText.trim().split("\n")[0],
        submissions[i].fields.step_1_field_1.value,
        `Step 1 is displayed correctly for submission ${i + 1}`
      );
      assert.equal(
        step2Cell.innerText.trim().split("\n")[0],
        submissions[i].fields.step_2_field_1.value,
        `Step 2 is displayed correctly for submission ${i + 1}`
      );
    }

    assert.ok(
      queryAll("table tbody tr").length >= 1,
      "Displays submissions list for another wizard"
    );
  });
  test("Modal actions for submissions", async (assert) => {
    await visit("/admin/wizards/submissions");
    const wizards = await selectKit(".select-kit");
    await wizards.expand();
    await wizards.selectRowByValue("this_is_testing_wizard");

    await click(".open-edit-columns-btn");
    assert.dom(".d-modal__body").exists("Modal is displayed");

    const userCheckbox = queryAll(
      ".edit-directory-columns-container .edit-directory-column:nth-child(2) .left-content .column-name input"
    );
    assert.ok(userCheckbox, "User checkbox is present");
    assert.ok(userCheckbox[0].checked, "User checkbox is checked by default");
    await click(userCheckbox[0]);
    assert.notOk(
      userCheckbox[0].checked,
      "User checkbox is unchecked after clicking"
    );

    await click(".modal-footer .btn-primary");
    assert
      .dom("table thead th")
      .doesNotIncludeText("User", "User column is not displayed");

    await click(".open-edit-columns-btn");
    const submittedAtCheckbox = queryAll(
      ".edit-directory-columns-container .edit-directory-column:nth-child(1) .left-content .column-name input"
    );
    assert.ok(submittedAtCheckbox, "Submitted At checkbox is present");
    assert.ok(
      submittedAtCheckbox[0].checked,
      "Submitted At checkbox is checked by default"
    );
    await click(submittedAtCheckbox[0]);

    await click(".modal-footer .btn-primary");
    assert.notOk(
      submittedAtCheckbox[0].checked,
      "Submitted At checkbox is unchecked after clicking"
    );
    assert
      .dom("table thead th")
      .doesNotIncludeText(
        "Submitted At",
        "Submitted At column is not displayed"
      );

    await click(".open-edit-columns-btn");
    await click(".modal-footer .btn-secondary");

    assert
      .dom("table thead th:nth-child(1)")
      .hasText("Submitted At", "Submitted At column is displayed after reset");
    assert
      .dom("table thead th:nth-child(2)")
      .hasText("User", "User column is displayed after reset");
  });
  test("Download submissions", async (assert) => {
    await visit("/admin/wizards/submissions");
    const wizards = await selectKit(".select-kit");
    await wizards.expand();
    await wizards.selectRowByValue("this_is_testing_wizard");

    const downloadLinks = queryAll(".download-link");
    assert.ok(downloadLinks.length > 1, "Download links are present");

    const downloadLink = downloadLinks[1];
    await click(downloadLink);

    const expectedURL =
      "/admin/wizards/submissions/this_is_testing_wizard/download";
    const actualURL = new URL(downloadLink.href);
    assert.equal(
      actualURL.pathname,
      expectedURL,
      "Download link has correct URL"
    );
  });
});
