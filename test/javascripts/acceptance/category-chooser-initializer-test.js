import { click, visit } from "@ember/test-helpers";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { test } from "qunit";

acceptance("CategoryChooser", function (needs) {
  needs.user();
  needs.settings({
    allow_uncategorized_topics: false,
  });

  test("does not display category with custom_wizard_hide_from_composer set to 't'", async function (assert) {
    const categoryChooser = selectKit(".category-chooser");

    await visit("/");
    await click("#create-topic");
    await categoryChooser.expand();

    assert.ok(categoryChooser.rowByIndex(4).name() !== "Custom Categories");
  });
});
