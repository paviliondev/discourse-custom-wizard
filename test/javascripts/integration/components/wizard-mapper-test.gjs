import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import WizardMapper from "discourse/plugins/discourse-custom-wizard/discourse/components/wizard-mapper";
import CustomWizardAdmin from "discourse/plugins/discourse-custom-wizard/discourse/models/custom-wizard-admin";

const options = {
  inputTypes: "validation",
  inputConnector: "or",
  textSelection: true,
};

function condition(value, props = {}) {
  return {
    type: "validation",
    pairs: [
      {
        index: 0,
        key: "Saved key",
        key_type: "text",
        value,
        value_type: "text",
        connector: "equal",
      },
    ],
    ...props,
  };
}

function stepCondition(...conditions) {
  const wizard = CustomWizardAdmin.create({
    id: "test_wizard",
    steps: [{ id: "step_1", condition: conditions }],
  });

  return wizard.steps[0].condition;
}

async function renderMapper(inputs) {
  await render(
    <template>
      <WizardMapper @inputs={{inputs}} @options={{options}} />
    </template>
  );
}

module("Integration | Component | wizard-mapper", function (hooks) {
  setupRenderingTest(hooks);

  test("renders every saved input and the connector between them", async function (assert) {
    await renderMapper(
      stepCondition(condition("one"), condition("two", { connector: "or" }))
    );

    assert
      .dom(".mapper-input")
      .exists({ count: 2 }, "both saved inputs render");
    assert
      .dom(".wizard-mapper > .mapper-connector")
      .hasText("or", "the connector between the inputs renders");
  });

  test("connects an added input to the existing ones", async function (assert) {
    const inputs = stepCondition(condition("one"));

    await renderMapper(inputs);
    await click(".add-mapper-input button");

    assert.dom(".mapper-input").exists({ count: 2 }, "the added input renders");
    assert.strictEqual(
      inputs[1].connector,
      "or",
      "the added input is connected to the first"
    );
  });
});
