import { click, fillIn, findAll, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import tagsJson from "../fixtures/tags";
import {
  getUnsubscribedAdminWizards,
  getWizard,
} from "../helpers/admin-wizard";

const VISIBLE_ACTION = ".wizard-custom-action.visible";
const USERNAMES_SETTING = `${VISIBLE_ACTION} .field-mapper-setting:last-child`;
const STEP_SETTINGS = ".wizard-custom-step > .field-mapper-setting";
const CONDITION = 0;
const REQUIRED_DATA = 1;
const [firstTag, secondTag] = tagsJson.tags;

function validation(value) {
  return {
    type: "validation",
    pairs: [
      {
        index: 0,
        key: "user_field_1",
        key_type: "user_field",
        value,
        value_type: "text",
        connector: "equal",
      },
    ],
  };
}

function assignment(output, outputType) {
  return [
    {
      type: "assignment",
      output,
      output_type: outputType,
      output_connector: "set",
    },
  ];
}

const mappedWizard = {
  id: "mapped_wizard",
  name: "Mapped wizard",
  save_submissions: true,
  permitted: assignment([13], "group"),
  steps: [
    {
      id: "step_1",
      title: "step 1",
      condition: [validation("one"), { ...validation("two"), connector: "or" }],
      fields: [{ id: "step_1_field_1", label: "label field", type: "text" }],
    },
  ],
  actions: [
    {
      id: "action_1",
      run_after: "wizard_completion",
      type: "create_topic",
      title: assignment("Topic title", "text"),
      category: assignment([30], "category"),
      tags: assignment(["gazelle"], "tag"),
      visible: [
        {
          type: "conditional",
          output: "Result text",
          output_type: "text",
          output_connector: "then",
          pairs: [
            {
              index: 0,
              key: "step_1_field_1",
              key_type: "wizard_field",
              value: "Some value",
              value_type: "text",
              connector: "equal",
            },
          ],
        },
      ],
    },
    {
      id: "action_2",
      run_after: "wizard_completion",
      type: "watch_tags",
      notification_level: "tracking",
      wizard_user: true,
      tags: assignment([firstTag.name], "tag"),
      usernames: assignment(["bruce1"], "user"),
    },
    {
      id: "action_3",
      run_after: "wizard_completion",
      type: "watch_tags",
      notification_level: "tracking",
      wizard_user: true,
      tags: assignment(["gazelle"], "tag"),
    },
  ],
};

acceptance("Admin | Custom Wizard | Mapped settings", function (needs) {
  let savedWizard = null;

  needs.user();
  needs.settings({
    custom_wizard_enabled: true,
    available_locales: JSON.stringify([{ name: "English", value: "en" }]),
  });

  needs.hooks.beforeEach(() => {
    savedWizard = null;
  });

  needs.pretender((server, helper) => {
    const responses = {
      "/admin/wizards/wizard": getWizard,
      "/admin/wizards/subscription": getUnsubscribedAdminWizards,
      "/admin/config/user_fields": { user_fields: [] },
      "/admin/wizards/wizard/mapped_wizard": mappedWizard,
    };

    Object.entries(responses).forEach(([url, response]) => {
      server.get(url, () => helper.response(response));
    });

    server.get("/tags/filter/search", () =>
      helper.response({ results: tagsJson.tags })
    );

    server.put("/admin/wizards/wizard/mapped_wizard", (request) => {
      savedWizard = JSON.parse(request.requestBody).wizard;
      return helper.response({ success: "OK", wizard_id: "mapped_wizard" });
    });
  });

  async function selectAction(id) {
    await click(`.wizard-links.action .link-list [data-id="${id}"] button`);
  }

  function stepSetting(index) {
    return findAll(STEP_SETTINGS)[index];
  }

  test("keeps mapped settings when a wizard is saved without changes", async function (assert) {
    await visit("/admin/wizards/wizard/mapped_wizard");
    await click(".admin-wizard-buttons button");

    assert.deepEqual(
      savedWizard.permitted,
      mappedWizard.permitted,
      "the permitted groups are unchanged"
    );

    for (const property of ["title", "category", "tags", "visible"]) {
      assert.deepEqual(
        savedWizard.actions[0][property],
        mappedWizard.actions[0][property],
        `the action ${property} is unchanged`
      );
    }

    for (const property of ["tags", "usernames"]) {
      assert.deepEqual(
        savedWizard.actions[1][property],
        mappedWizard.actions[1][property],
        `the watch tags action ${property} is unchanged`
      );
    }
  });

  test("saves tag names selected in a mapper", async function (assert) {
    await visit("/admin/wizards/wizard/mapped_wizard");
    await selectAction("action_1");

    const tags = selectKit(
      `${VISIBLE_ACTION} .mapper-selector.tag .tag-chooser`
    );
    await tags.expand();
    await tags.selectRowByValue(secondTag.id);
    await click(".admin-wizard-buttons button");

    assert.deepEqual(
      savedWizard.actions[0].tags[0].output,
      ["gazelle", secondTag.name],
      "the mapped tags are saved as tag names"
    );
  });

  test("does not save a tag twice when it is selected again", async function (assert) {
    await visit("/admin/wizards/wizard/mapped_wizard");
    await selectAction("action_2");

    const tags = selectKit(
      `${VISIBLE_ACTION} .mapper-selector.tag .tag-chooser`
    );
    await tags.expand();
    await tags.selectRowByValue(firstTag.id);
    await click(".admin-wizard-buttons button");

    assert.deepEqual(
      savedWizard.actions[1].tags[0].output,
      [firstTag.name],
      "the already mapped tag is not duplicated"
    );
  });

  test("adds an input to a mapper with no saved value", async function (assert) {
    await visit("/admin/wizards/wizard/mapped_wizard");
    await selectAction("action_3");

    assert
      .dom(`${USERNAMES_SETTING} .mapper-input`)
      .doesNotExist("no input renders for an unset mapper");

    await click(`${USERNAMES_SETTING} .add-mapper-input button`);

    assert
      .dom(`${USERNAMES_SETTING} .mapper-input`)
      .exists({ count: 1 }, "the added input renders");
  });

  test("restores the add button when the last input is removed", async function (assert) {
    await visit("/admin/wizards/wizard/mapped_wizard");
    await selectAction("action_2");

    assert
      .dom(`${USERNAMES_SETTING} .mapper-input`)
      .exists({ count: 1 }, "the saved usernames input renders");

    await click(`${USERNAMES_SETTING} .mapper-input .remove-input`);

    assert
      .dom(`${USERNAMES_SETTING} .mapper-input`)
      .doesNotExist("the removed input no longer renders");

    assert
      .dom(`${USERNAMES_SETTING} .add-mapper-input button`)
      .exists("the add button is available again");

    await click(`${USERNAMES_SETTING} .add-mapper-input button`);

    assert
      .dom(`${USERNAMES_SETTING} .mapper-input`)
      .exists({ count: 1 }, "the added input renders");
  });

  test("keeps every input of a step mapper when a wizard is saved", async function (assert) {
    await visit("/admin/wizards/wizard/mapped_wizard");

    assert
      .dom(".mapper-input", stepSetting(CONDITION))
      .exists({ count: 2 }, "both saved step conditions render");

    await click(".admin-wizard-buttons button");

    assert.deepEqual(
      savedWizard.steps[0].condition,
      mappedWizard.steps[0].condition,
      "the step conditions are unchanged"
    );
  });

  test("saves an input added to a step mapper", async function (assert) {
    await visit("/admin/wizards/wizard/mapped_wizard");

    await click(
      stepSetting(REQUIRED_DATA).querySelector(".add-mapper-input button")
    );
    await fillIn(
      stepSetting(REQUIRED_DATA).querySelector(".key .input input"),
      "submission_key"
    );
    await fillIn(
      stepSetting(REQUIRED_DATA).querySelector(".value .input input"),
      "field_key"
    );
    await click(".admin-wizard-buttons button");

    assert.deepEqual(
      savedWizard.steps[0].required_data,
      [
        {
          type: "validation",
          pairs: [
            {
              index: 0,
              key: "submission_key",
              key_type: "text",
              value: "field_key",
              value_type: "text",
              connector: "equal",
            },
          ],
        },
      ],
      "the added required data is saved"
    );
  });
});
