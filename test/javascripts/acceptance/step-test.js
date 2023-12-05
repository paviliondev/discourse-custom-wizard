import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  count,
  exists,
  query,
  visible,
} from "discourse/tests/helpers/qunit-helpers";
import { stepNotPermitted, update, wizard } from "../helpers/wizard";

acceptance("Step | Not permitted", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", () => helper.response(stepNotPermitted));
  });

  test("Shows not permitted message", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".step-message.not-permitted"));
  });
});

acceptance("Step | Step", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", () => helper.response(wizard));
    server.put("/w/wizard/steps/:step_id", () => helper.response(update));
  });

  test("Renders the step", async function (assert) {
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
    assert.ok(visible(".wizard-step-footer .wizard-progress"), true);
    assert.ok(visible(".wizard-step-footer .wizard-buttons"), true);
  });

  test("Goes to the next step", async function (assert) {
    await visit("/w/wizard");
    assert.ok(visible(".wizard-step.step_1"), true);
    await click(".wizard-btn.next");
    assert.ok(visible(".wizard-step.step_2"), true);
  });
});
