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
    });
  }
};
