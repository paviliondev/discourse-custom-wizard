export default {
  resource: 'admin',
  map() {
    this.route('adminWizards', { path: '/wizards', resetNamespace: true }, function() {
      this.route('adminWizardsCustom', { path: '/custom', resetNamespace: true }, function() {
        this.route('adminWizard', { path: '/:wizard_id', resetNamespace: true });
      });
      this.route('adminWizardsSubmissions', { path: '/submissions', resetNamespace: true }, function() {
        this.route('adminWizardSubmissions', { path: '/:wizard_id', resetNamespace: true });
      });
      this.route('adminWizardsApis', { path: '/apis', resetNamespace: true }, function() {
        this.route('adminWizardsApi', { path: '/:name', resetNamespace: true });
      });

      this.route('adminWizardsTransfer', { path: '/transfer', resetNamespace: true });

    });
  }
};
