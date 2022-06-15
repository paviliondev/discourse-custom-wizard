export default {
  run(app, container) {
    const { createHelperContext } = requirejs("discourse-common/lib/helpers");

    createHelperContext({
      siteSettings: container.lookup("site-settings:main"),
      site: container.lookup("site:main"),
      session: container.lookup("session:main"),
      capabilities: container.lookup("capabilities:main"),
    });
  },
};
