import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import CustomWizardFieldDropdown from "discourse/plugins/discourse-custom-wizard/discourse/components/custom-wizard-field-dropdown";

module(
  "Integration | Component | custom-wizard-field-dropdown",
  function (hooks) {
    setupRenderingTest(hooks);

    test("shows every option when content is a list of strings", async function (assert) {
      const field = {
        id: "step_1_field_1",
        value: null,
        content: ["Man", "Woman", "Non-Binary", "Prefer not to say"],
      };

      await render(
        <template><CustomWizardFieldDropdown @field={{field}} /></template>
      );

      const dropdown = selectKit(".combo-box");
      await dropdown.expand();

      assert.strictEqual(dropdown.rows().length, 4);
      assert.true(dropdown.rowByValue("Woman").exists());
      assert.strictEqual(dropdown.rowByValue("Woman").name(), "Woman");
    });

    test("sets the selected string as the field value", async function (assert) {
      const field = {
        id: "step_1_field_1",
        value: null,
        content: ["Man", "Woman", "Non-Binary", "Prefer not to say"],
      };

      await render(
        <template><CustomWizardFieldDropdown @field={{field}} /></template>
      );

      const dropdown = selectKit(".combo-box");
      await dropdown.expand();
      await dropdown.selectRowByValue("Woman");

      assert.strictEqual(field.value, "Woman");
      assert.strictEqual(dropdown.header().value(), "Woman");
    });

    test("shows a prefilled string value", async function (assert) {
      const field = {
        id: "step_1_field_1",
        value: "Non-Binary",
        content: ["Man", "Woman", "Non-Binary", "Prefer not to say"],
      };

      await render(
        <template><CustomWizardFieldDropdown @field={{field}} /></template>
      );

      const dropdown = selectKit(".combo-box");

      assert.strictEqual(dropdown.header().value(), "Non-Binary");
      assert.strictEqual(dropdown.header().label(), "Non-Binary");
    });

    test("keeps id and name content", async function (assert) {
      const field = {
        id: "step_1_field_1",
        value: null,
        content: [
          { id: "a", name: "Option A" },
          { id: "b", name: "Option B" },
        ],
      };

      await render(
        <template><CustomWizardFieldDropdown @field={{field}} /></template>
      );

      const dropdown = selectKit(".combo-box");
      await dropdown.expand();

      assert.strictEqual(dropdown.rows().length, 2);
      assert.strictEqual(dropdown.rowByValue("b").name(), "Option B");
    });
  }
);
