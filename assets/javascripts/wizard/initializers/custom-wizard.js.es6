export default {
  name: "custom-routes",
  initialize(app) {
    if (window.location.pathname.indexOf("/w/") < 0) return;

    const EmberObject = requirejs("@ember/object").default;
    const Router = requirejs("wizard/router").default;
    const ApplicationRoute = requirejs("wizard/routes/application").default;
    const CustomWizard = requirejs("discourse/plugins/discourse-custom-wizard/wizard/models/custom").default;
    const getUrl = requirejs("discourse-common/lib/get-url").default;
    const Store = requirejs("discourse/models/store").default;
    const registerRawHelpers = requirejs("discourse-common/lib/raw-handlebars-helpers").registerRawHelpers;
    const createHelperContext = requirejs("discourse-common/lib/helpers").createHelperContext;
    const RawHandlebars = requirejs("discourse-common/lib/raw-handlebars").default;
    const Site = requirejs("discourse/plugins/discourse-custom-wizard/wizard/models/site").default;
    const RestAdapter = requirejs("discourse/adapters/rest").default;
    const Session = requirejs("discourse/models/session").default;
    const setDefaultOwner = requirejs("discourse-common/lib/get-owner").setDefaultOwner;
    const messageBus = requirejs("message-bus-client").default;
    
    const container = app.__container__;
    Discourse.Model = EmberObject.extend();
    Discourse.__container__ = container;
    setDefaultOwner(container);
    registerRawHelpers(RawHandlebars, Handlebars);

    // IE11 Polyfill - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/entries#Polyfill
    if (!Object.entries) {
      Object.entries = function (obj) {
        var ownProps = Object.keys(obj),
          i = ownProps.length,
          resArray = new Array(i); // preallocate the Array
        while (i--) resArray[i] = [ownProps[i], obj[ownProps[i]]];

        return resArray;
      };
    }

    Object.keys(Ember.TEMPLATES).forEach((k) => {
      if (k.indexOf("select-kit") === 0) {
        let template = Ember.TEMPLATES[k];
        define(k, () => template);
      }
    });

    const targets = ["controller", "component", "route", "model", "adapter"];

    const siteSettings = Wizard.SiteSettings;
    app.register("site-settings:main", siteSettings, { instantiate: false });
    createHelperContext({ siteSettings });
    targets.forEach((t) => app.inject(t, "siteSettings", "site-settings:main"));

    app.register("message-bus:main", messageBus, { instantiate: false });
    targets.forEach((t) => app.inject(t, "messageBus", "message-bus:main"));

    app.register("service:store", Store);
    targets.forEach((t) => app.inject(t, "store", "service:store"));
    targets.forEach((t) => app.inject(t, "appEvents", "service:app-events"));

    app.register("adapter:rest", RestAdapter);

    const site = Site.current();
    app.register("site:main", site, { instantiate: false });
    targets.forEach((t) => app.inject(t, "site", "site:main"));

    site.set("can_create_tag", false);
    app.register("session:main", Session.current(), { instantiate: false });
    targets.forEach((t) => app.inject(t, "session", "session:main"));
    
    createHelperContext({
      siteSettings: container.lookup("site-settings:main"),
      currentUser: container.lookup("current-user:main"),
      site: container.lookup("site:main"),
      session: container.lookup("session:main"),
      capabilities: container.lookup("capabilities:main"),
    });
    
    const session = container.lookup("session:main");
    const setupData = document.getElementById("data-discourse-setup").dataset;
    session.set("highlightJsPath", setupData.highlightJsPath);
    
    Router.reopen({
      rootURL: getUrl("/w/")
    });

    Router.map(function () {
      this.route("custom", { path: "/:wizard_id" }, function () {
        this.route("steps");
        this.route("step", { path: "/steps/:step_id" });
      });
    });

    ApplicationRoute.reopen({
      redirect() {
        this.transitionTo("custom");
      },
      model() {},
    });
  },
};
