export default {
  run(app) {
    // siteSettings must always be registered first
    if (!app.hasRegistration("site-settings:main")) {
      const siteSettings = app.SiteSettings;
      app.register("site-settings:main", siteSettings, { instantiate: false });
    }

    const Store = requirejs("discourse/services/store").default;
    const Site = requirejs(
      "discourse/plugins/discourse-custom-wizard/wizard/models/site"
    ).default;
    const Session = requirejs("discourse/models/session").default;
    const RestAdapter = requirejs("discourse/adapters/rest").default;
    const messageBus = requirejs("message-bus-client").default;
    const sniffCapabilites = requirejs(
      "discourse/pre-initializers/sniff-capabilities"
    ).default;

    const site = Site.current();
    const session = Session.current();
    const registrations = [
      ["message-bus:main", messageBus, false],
      ["site:main", site, false],
      ["session:main", session, false],
      ["service:store", Store, true],
      ["adapter:rest", RestAdapter, true],
    ];

    registrations.forEach((registration) => {
      if (!app.hasRegistration(registration[0])) {
        app.register(registration[0], registration[1], {
          instantiate: registration[2],
        });
      }
    });

    const targets = ["controller", "component", "route", "model", "adapter"];

    targets.forEach((t) => {
      app.inject(t, "appEvents", "service:app-events");
      app.inject(t, "store", "service:store");
      app.inject(t, "site", "site:main");
    });

    targets.concat("service").forEach((t) => {
      app.inject(t, "session", "session:main");
      app.inject(t, "messageBus", "message-bus:main");
      app.inject(t, "siteSettings", "site-settings:main");
    });

    if (!app.hasRegistration("capabilities:main")) {
      sniffCapabilites.initialize(null, app);
    }

    site.set("can_create_tag", false);
  },
};
