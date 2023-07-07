export default {
  name: "custom-wizard-redirect",
  after: "message-bus",

  initialize: function (container) {
    const messageBus = container.lookup("service:message-bus");
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.custom_wizard_enabled || !messageBus) {
      return;
    }

    messageBus.subscribe("/redirect_to_wizard", function (wizardId) {
      const wizardUrl = window.location.origin + "/w/" + wizardId;
      window.location.href = wizardUrl;
    });

    const ApplicationRoute = requirejs("discourse/routes/application").default

    ApplicationRoute.reopen({
      actions: {
        willTransition(transition) {
          const redirectToWizard = this.get("currentUser.redirect_to_wizard");
          const excludedPaths = this.siteSettings.wizard_redirect_exclude_paths
            .split("|")
            .concat(["loading"]);

          if (
            redirectToWizard &&
            (!transition.intent.name ||
              !excludedPaths.find((p) => {
                return transition.intent.name.indexOf(p) > -1;
              }))
          ) {
            transition.abort();
            window.location = "/w/" + redirectToWizard.dasherize();
          }

          return this._super(transition);
        },
      },
    });
  },
};
