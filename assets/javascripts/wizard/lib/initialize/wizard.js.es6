export default {
  name: "custom-wizard",
  initialize(app) {
    const isTesting = requirejs("discourse-common/config/environment")
      .isTesting;
    const isWizard = window.location.pathname.indexOf("/w/") > -1;

    if (!isWizard && !isTesting()) {
      return;
    }

    const container = app.__container__;
    const setDefaultOwner = requirejs("discourse-common/lib/get-owner")
      .setDefaultOwner;
    setDefaultOwner(container);

    if (!isTesting()) {
      const PreloadStore = requirejs("discourse/lib/preload-store").default;

      let preloaded;
      const preloadedDataElement = document.getElementById(
        "data-preloaded-wizard"
      );
      if (preloadedDataElement) {
        preloaded = JSON.parse(preloadedDataElement.dataset.preloadedWizard);
      }

      Object.keys(preloaded).forEach(function (key) {
        PreloadStore.store(key, JSON.parse(preloaded[key]));
      });

      app.SiteSettings = PreloadStore.get("siteSettings");
    }

    const setEnvironment = requirejs("discourse-common/config/environment")
      .setEnvironment;
    const setupData = document.getElementById("data-discourse-setup").dataset;
    setEnvironment(setupData.environment);

    const Session = requirejs("discourse/models/session").default;
    const session = Session.current();
    session.set("highlightJsPath", setupData.highlightJsPath);
    session.set("markdownItUrl", setupData.markdownItUrl);

    [
      "register-files",
      "inject-objects",
      "create-contexts",
      "patch-components",
    ].forEach((fileName) => {
      const initializer = requirejs(
        `discourse/plugins/discourse-custom-wizard/wizard/lib/initialize/${fileName}`
      ).default;
      initializer.run(app, container);
    });
  },
};
