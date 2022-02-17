import { click, currentRouteName, fillIn, visit } from "@ember/test-helpers";
import { module, test } from "qunit";
import { run } from "@ember/runloop";
import startApp from "../helpers/start-app";
console.log("STARTING TEST");
let wizard;
window.onerror = function (msg, url, lineNo, columnNo, error) {
  console.log(error);
  return false
}
module("Acceptance: Custom Wizard", {
  beforeEach() {
    console.log("BEFORE EACH")
    wizard = startApp();
  },

  afterEach() {
    run(wizard, "destroy");
  },
});

function exists(selector) {
  return document.querySelector(selector) !== null;
}

test("Wizard starts", async function (assert) {
  console.log("TEST")
  await visit("/w/wizard");
  assert.ok(exists(".wizard-column"));
});
