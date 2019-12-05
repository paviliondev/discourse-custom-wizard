import ApplicationRoute from 'discourse/routes/application';

export default {
  name: "custom-wizard-redirect",
  after: "message-bus",

  initialize: function (container) {
    const messageBus = container.lookup('message-bus:main');
    const siteSettings = container.lookup('site-settings:main');
    
    if (!siteSettings.custom_wizard_enabled || !messageBus) return;

    messageBus.subscribe("/redirect_to_wizard", function (wizardId) {
      const wizardUrl = window.location.origin + '/w/' + wizardId;
      window.location.href = wizardUrl;
    });

    ApplicationRoute.reopen({
      actions: {
        willTransition(transition) {
          const redirectToWizard = this.get('currentUser.redirect_to_wizard');
          const excludedPaths = Discourse.SiteSettings.wizard_redirect_exclude_paths.split('|').concat(['loading']);

          if (redirectToWizard && (!transition.intent.name || !excludedPaths.find((p) => {
            return transition.intent.name.indexOf(p) > -1;
          }))) {
            transition.abort();
            window.location = '/w/' + redirectToWizard.dasherize();
          }

          return this._super(transition);
        }
      }
    })
  }
};
