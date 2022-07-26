import { click, fillIn, triggerKeyEvent, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { exists } from "../helpers/test";
import acceptance, {
  count,
  query,
  server,
  visible,
} from "../helpers/acceptance";
import { allFieldsWizard, getWizard } from "../helpers/wizard";
import tagsJson from "../fixtures/tags";
import usersJson from "../fixtures/users";
import { response } from "../pretender";

acceptance("Field | Fields", [getWizard(allFieldsWizard)], function () {
  test("Text", async function (assert) {
    await visit("/wizard");
    assert.ok(exists(".wizard-field.text-field input.wizard-focusable"));
  });

  test("Textarea", async function (assert) {
    await visit("/wizard");
    assert.ok(
      visible(".wizard-field.textarea-field textarea.wizard-focusable")
    );
  });

  test("Composer", async function (assert) {
    await visit("/wizard");
    assert.ok(
      visible(".wizard-field.composer-field .wizard-field-composer textarea")
    );
    assert.strictEqual(
      count(".wizard-field.composer-field .d-editor-button-bar button"),
      8
    );
    assert.ok(visible(".wizard-btn.toggle-preview"));

    await fillIn(
      ".wizard-field.composer-field .wizard-field-composer textarea",
      "Input in composer"
    );
    await click(".wizard-btn.toggle-preview");
    assert.strictEqual(
      query(
        ".wizard-field.composer-field .wizard-field-composer .d-editor-preview-wrapper p"
      ).textContent.trim(),
      "Input in composer"
    );
  });

  test("Text Only", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.text-only-field label.field-label"));
  });

  test("Date", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.date-field input.date-picker"));
    await click(".wizard-field.date-field input.date-picker");
    assert.ok(visible(".wizard-field.date-field .pika-single"));
  });

  test("Time", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.time-field .d-time-input .select-kit"));
    await click(
      ".wizard-field.time-field .d-time-input .select-kit .select-kit-header"
    );
    assert.ok(visible(".wizard-field.time-field .select-kit-collection"));
  });

  test("Date Time", async function (assert) {
    await visit("/wizard");
    assert.ok(
      visible(".wizard-field.date-time-field .d-date-time-input .select-kit")
    );
    await click(
      ".wizard-field.date-time-field .d-date-input input.date-picker"
    );
    assert.ok(
      visible(".wizard-field.date-time-field .d-date-input .pika-single")
    );
    await click(
      ".wizard-field.date-time-field .d-time-input .select-kit .select-kit-header"
    );
    assert.ok(visible(".wizard-field.date-time-field .select-kit-collection"));
  });

  test("Number", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.number-field input[type='number']"));
  });

  test("Checkbox", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.checkbox-field input[type='checkbox']"));
  });

  test("Url", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.url-field input[type='text']"));
  });

  test("Upload", async function (assert) {
    await visit("/wizard");
    assert.ok(
      visible(".wizard-field.upload-field label.wizard-btn-upload-file")
    );
    assert.ok(exists(".wizard-field.upload-field input.hidden-upload-field"));
  });

  test("Dropdown", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.dropdown-field .single-select-header"));
    await click(".wizard-field.dropdown-field .select-kit-header");
    assert.strictEqual(
      count(".wizard-field.dropdown-field .select-kit-collection li"),
      3
    );
  });

  test("Tag", async function (assert) {
    server.get("/tags/filter/search", () =>
      response(200, { results: tagsJson["tags"] })
    );
    await visit("/wizard");
    assert.ok(visible(".wizard-field.tag-field .multi-select-header"));
    await click(".wizard-field.tag-field .select-kit-header");
    assert.strictEqual(
      count(".wizard-field.tag-field .select-kit-collection li"),
      2
    );
  });

  test("Category", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.category-field .multi-select-header"));
    await click(".wizard-field.category-field .select-kit-header");
    assert.strictEqual(
      count(".wizard-field.category-field .select-kit-collection li"),
      5
    );
  });

  test("Group", async function (assert) {
    await visit("/wizard");
    assert.ok(visible(".wizard-field.group-field .single-select-header"));
    await click(".wizard-field.group-field .select-kit-header");
    assert.strictEqual(
      count(".wizard-field.group-field .select-kit-collection li"),
      10
    );
  });

  test("User", async function (assert) {
    server.get("/u/search/users", () => response(200, usersJson));

    await visit("/wizard");
    await fillIn(
      ".wizard-field.user-selector-field input.ember-text-field",
      "a"
    );
    await triggerKeyEvent(
      ".wizard-field.user-selector-field input.ember-text-field",
      "keyup",
      "a".charCodeAt(0)
    );

    assert.ok(visible(".wizard-field.user-selector-field .ac-wrap"));
    // TODO: add assertion for ac results. autocomplete does not appear in time.
  });
});
