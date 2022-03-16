export default {
  run(app, container) {
    const Store = requirejs("discourse/services/store").default;
    const Site = requirejs(
      "discourse/plugins/discourse-custom-wizard/wizard/models/site"
    ).default;
    const Session = requirejs("discourse/models/session").default;
    const RestAdapter = requirejs("discourse/adapters/rest").default;
    const messageBus = requirejs("message-bus-client").default;
    const sniffCapabilites = requirejs("discourse/pre-initializers/sniff-capabilities").default;
    const site = Site.current();
    const session = Session.current();

    const registrations = [
      ["site-settings:main", app.SiteSettings, false],
      ["message-bus:main", messageBus, false],
      ["site:main", site, false],
      ["session:main", session, false],
      ["service:store", Store, true],
      ["adapter:rest", RestAdapter, true]
    ];

    registrations.forEach(registration => {
      if (!app.hasRegistration(registration[0])) {
        app.register(registration[0], registration[1], { instantiate: registration[2] });
      }
    });

    const targets = ["controller", "component", "route", "model", "adapter", "mixin"];
    const injections = [
      ["siteSettings", "site-settings:main"],
      ["messageBus", "message-bus:main"],
      ["site", "site:main"],
      ["session", "session:main"],
      ["store", "service:store"],
      ["appEvents", "service:app-events"]
    ];

    injections.forEach(injection => {
      targets.forEach((t) => app.inject(t, injection[0], injection[1]));
    });

    if (!app.hasRegistration("capabilities:main")) {
      sniffCapabilites.initialize(null, app);
    }

    site.set("can_create_tag", false);
  }
}
