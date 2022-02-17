import CustomWizard from "discourse/plugins/discourse-custom-wizard/wizard/custom-wizard";
import wizardInitializer from "discourse/plugins/discourse-custom-wizard/wizard/initializers/custom-wizard";
import stepInitializer from "discourse/plugins/discourse-custom-wizard/wizard/initializers/custom-wizard-step";
import fieldInitializer from "discourse/plugins/discourse-custom-wizard/wizard/initializers/custom-wizard-field";
import { run } from "@ember/runloop";

let app;
let started = false;

export default function () {
  run(() => (app = CustomWizard.create({ rootElement: "#ember-testing" })));

  if (!started) {
    wizardInitializer.initialize(app);
    stepInitializer.initialize(app);
    fieldInitializer.initialize(app);
    app.start();
    started = true;
  }
  app.setupForTesting();
  app.injectTestHelpers();
  return app;
}
