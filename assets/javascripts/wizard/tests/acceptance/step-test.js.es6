import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { exists } from "../helpers/test";
import acceptance, { count, query, visible } from "../helpers/acceptance";
import { getWizard, stepNotPermitted, wizard } from "../helpers/wizard";
import { saveStep, update } from "../helpers/step";

acceptance("Step | Not permitted", [getWizard(stepNotPermitted)], function () {
  test("Shows not permitted message", async function (assert) {
    await visit("/wizard");
    assert.ok(exists(".step-message.not-permitted"));
  });
});

acceptance("Step | Step", [getWizard(wizard), saveStep(update)], function () {
  test("Renders the step", async function (assert) {
    await visit("/wizard");
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
    assert.ok(visible(".wizard-step-footer .wizard-progress"), true);
    assert.ok(visible(".wizard-step-footer .wizard-buttons"), true);
  });

  test("Goes to the next step", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-step.step_1"), true);
    await click(".wizard-btn.next");
    assert.ok(visible(".wizard-step.step_2"), true);
  });
});
