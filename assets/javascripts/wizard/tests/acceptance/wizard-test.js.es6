import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { exists } from "../helpers/test";
import acceptance, {
  query,
  count,
  visible
} from "../helpers/acceptance";
import {
  wizardNoUser,
  wizardNotPermitted,
  wizardCompleted,
  wizard,
  getWizard
} from "../helpers/wizard";

acceptance("Wizard | Not logged in", [ getWizard(wizardNoUser) ],
  function(hooks) {
    test("Wizard no access requires login", async function (assert) {
      await visit("/wizard");
      assert.ok(exists(".wizard-no-access.requires-login"));
    });
  }
);

acceptance("Wizard | Not permitted", [ getWizard(wizardNotPermitted) ],
  function(hooks) {
    test("Wizard no access not permitted", async function (assert) {
      await visit("/wizard");
      assert.ok(exists(".wizard-no-access.not-permitted"));
    });
  }
);

acceptance("Wizard | Completed", [ getWizard(wizardCompleted) ],
  function(hooks) {
    test("Wizard no access completed", async function (assert) {
      await visit("/wizard");
      assert.ok(exists(".wizard-no-access.completed"));
    });
  }
);

acceptance("Wizard | Wizard", [ getWizard(wizard) ],
  function(hooks) {
    test("Starts", async function (assert) {
      await visit("/wizard");
      assert.ok(query('.wizard-column'), true);
    });

    test("Applies the body background color", async function (assert) {
      await visit("/wizard");
      assert.ok($("body")[0].style.background);
    });

    test("Renders the wizard form", async function (assert) {
      await visit("/wizard");
      assert.ok(visible('.wizard-column-contents .wizard-step'), true);
      assert.ok(visible('.wizard-footer img'), true);
    });

    test("Renders the first step", async function (assert) {
      await visit("/wizard");
      assert.strictEqual(query('.wizard-step-title p').textContent.trim(), "Text");
      assert.strictEqual(query('.wizard-step-description p').textContent.trim(), "Text inputs!");
      assert.strictEqual(query('.wizard-step-description p').textContent.trim(), "Text inputs!");
      assert.strictEqual(count('.wizard-step-form .wizard-field'), 6);
      assert.ok(visible('.wizard-step-footer .wizard-progress'), true);
      assert.ok(visible('.wizard-step-footer .wizard-buttons'), true);
    });
  }
);
