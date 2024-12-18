import { click, visit } from "@ember/test-helpers";
import $ from "jquery";
import { test } from "qunit";
import sinon from "sinon";
import DiscourseURL from "discourse/lib/url";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import {
  acceptance,
  count,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import I18n from "I18n";
import {
  wizard,
  wizardCompleted,
  wizardGuest,
  wizardNotPermitted,
  wizardNoUser,
  wizardResumeOnRevisit,
} from "../helpers/wizard";

acceptance("Wizard | Not logged in", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", () => helper.response(wizardNoUser));
  });

  test("Requires login", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-no-access.requires-login"));
  });

  test("Requires login if a step path is used", async function (assert) {
    await visit("/w/wizard/steps/1");
    assert.ok(exists(".wizard-no-access.requires-login"));
  });
});

acceptance("Wizard | Not permitted", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", () => helper.response(wizardNotPermitted));
  });

  test("Wizard no access not permitted", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-no-access.not-permitted"));
  });
});

acceptance("Wizard | Completed", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", () => helper.response(wizardCompleted));
  });

  test("Wizard no access completed", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-no-access.completed"));
  });
});

acceptance("Wizard | Redirect", function (needs) {
  needs.user({
    redirect_to_wizard: "wizard",
  });
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", () => {
      return helper.response(wizard);
    });
  });

  test("Redirect to pending Wizard", async function (assert) {
    sinon.stub(DiscourseURL, "routeTo");
    await visit("/latest");
    assert.ok(
      DiscourseURL.routeTo.calledWith("/w/wizard"),
      "pending wizard routing works"
    );
  });

  test("Don't redirect to pending Wizard when ingore redirect param is supplied", async function (assert) {
    sinon.stub(DiscourseURL, "routeTo");
    await visit("/latest?ignore_redirect=1");
    assert.notOk(
      DiscourseURL.routeTo.calledWith("/w/wizard"),
      "pending wizard routing blocked"
    );
  });
});

acceptance("Wizard | Wizard", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", () => {
      return helper.response(wizard);
    });
  });

  test("Starts", async function (assert) {
    await visit("/w/wizard");
    assert.ok(query(".wizard-column"), true);
  });

  test("Applies the wizard body class", async function (assert) {
    await visit("/w/wizard");
    assert.ok($("body.custom-wizard").length);
  });

  test("Applies the body background color", async function (assert) {
    await visit("/w/wizard");
    assert.ok($("body")[0].style.background);
  });

  test("Renders the wizard form", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-column-contents .wizard-step"), true);
    assert.ok(exists(".wizard-footer img"), true);
  });

  test("Renders the first step", async function (assert) {
    await visit("/w/wizard");
    assert.strictEqual(
      query(".wizard-step-title p").textContent.trim(),
      "Text"
    );
    assert.strictEqual(
      query(".wizard-step-description p").textContent.trim(),
      "Text inputs!"
    );
    assert.strictEqual(
      query(".wizard-step-description p").textContent.trim(),
      "Text inputs!"
    );
    assert.strictEqual(count(".wizard-step-form .wizard-field"), 6);
    assert.ok(exists(".wizard-step-footer .wizard-progress"), true);
    assert.ok(exists(".wizard-step-footer .wizard-buttons"), true);
  });

  test("Removes the wizard body class when navigating away", async function (assert) {
    await visit("/");
    assert.strictEqual($("body.custom-wizard").length, 0);
  });
});

acceptance("Wizard | Guest access", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", () => helper.response(wizardGuest));
  });

  test("Does not require login", async function (assert) {
    await visit("/w/wizard");
    assert.ok(!exists(".wizard-no-access.requires-login"));
  });

  test("Starts", async function (assert) {
    await visit("/w/wizard");
    assert.ok(query(".wizard-column"), true);
  });

  test("Applies the wizard body class", async function (assert) {
    await visit("/w/wizard");
    assert.ok($("body.custom-wizard").length);
  });

  test("Applies the body background color", async function (assert) {
    await visit("/w/wizard");
    assert.ok($("body")[0].style.background);
  });

  test("Renders the wizard form", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-column-contents .wizard-step"), true);
    assert.ok(exists(".wizard-footer img"), true);
  });

  test("Renders the first step", async function (assert) {
    await visit("/w/wizard");
    assert.strictEqual(
      query(".wizard-step-title p").textContent.trim(),
      "Text"
    );
    assert.strictEqual(
      query(".wizard-step-description p").textContent.trim(),
      "Text inputs!"
    );
    assert.strictEqual(
      query(".wizard-step-description p").textContent.trim(),
      "Text inputs!"
    );
    assert.strictEqual(count(".wizard-step-form .wizard-field"), 6);
    assert.ok(exists(".wizard-step-footer .wizard-progress"), true);
    assert.ok(exists(".wizard-step-footer .wizard-buttons"), true);
  });

  test("Removes the wizard body class when navigating away", async function (assert) {
    await visit("/");
    assert.strictEqual($("body.custom-wizard").length, 0);
  });
});

acceptance("Wizard | Resume on revisit", function (needs) {
  needs.user();

  test("Shows dialog", async function (assert) {
    pretender.get("/w/wizard.json", () => {
      return response(wizardResumeOnRevisit);
    });

    await visit("/w/wizard");

    assert.strictEqual(count(".dialog-content:visible"), 1);
    assert.strictEqual(
      query(".dialog-header h3").textContent.trim(),
      I18n.t("wizard.incomplete_submission.title", {
        date: moment(wizardResumeOnRevisit.submission_last_updated_at).format(
          "MMMM Do YYYY"
        ),
      })
    );
  });

  test("Resumes when resumed", async function (assert) {
    pretender.get("/w/wizard.json", () => {
      return response(wizardResumeOnRevisit);
    });
    await visit("/w/wizard");
    await click(".dialog-footer .btn-primary");
    assert.strictEqual(count(".dialog-content:visible"), 0);
  });

  test("Restarts when restarted", async function (assert) {
    sinon.stub(DiscourseURL, "redirectTo");
    let skips = 0;
    pretender.get("/w/wizard.json", () => {
      return response(wizardResumeOnRevisit);
    });
    pretender.put("/w/wizard/skip", () => {
      skips++;
      return response({});
    });
    await visit("/w/wizard");
    await click(".dialog-footer .btn-default");
    assert.strictEqual(skips, 1);
    assert.ok(
      DiscourseURL.redirectTo.calledWith("/w/wizard"),
      "resuming wizard works"
    );
  });
});
