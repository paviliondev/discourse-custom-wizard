const CustomWizard = requirejs(
  "discourse/plugins/discourse-custom-wizard/wizard/application"
).default;
const initializer = requirejs(
  "discourse/plugins/discourse-custom-wizard/wizard/lib/initialize/wizard"
).default;
const siteSettings = requirejs(
  "discourse/plugins/discourse-custom-wizard/wizard/tests/fixtures/site-settings"
).default;
const { cloneJSON } = requirejs("discourse-common/lib/object").default;

let app;

export default function () {
  app = CustomWizard.create({ rootElement: "#ember-testing" });
  app.start();

  app.SiteSettings = cloneJSON(siteSettings);
  initializer.initialize(app);

  app.setupForTesting();
  app.injectTestHelpers();

  return app;
}
