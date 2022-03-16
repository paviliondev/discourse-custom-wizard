export default {
  run(app, container) {
    const RawHandlebars = requirejs("discourse-common/lib/raw-handlebars")
      .default;
    const Handlebars = requirejs("handlebars").default;
    const registerRawHelpers = requirejs(
      "discourse-common/lib/raw-handlebars-helpers"
    ).registerRawHelpers;
    const { registerHelpers } = requirejs("discourse-common/lib/helpers");
    const jqueryPlugins = requirejs("discourse/initializers/jquery-plugins")
      .default;

    Object.keys(Ember.TEMPLATES).forEach((k) => {
      if (k.indexOf("select-kit") === 0) {
        let template = Ember.TEMPLATES[k];
        define(k, () => template);
      }
    });

    Object.keys(requirejs.entries).forEach((entry) => {
      if (/\/helpers\//.test(entry)) {
        requirejs(entry, null, null, true);
      }
    });

    registerRawHelpers(RawHandlebars, Handlebars);
    registerHelpers(app);
    jqueryPlugins.initialize(container, app);
  },
};
