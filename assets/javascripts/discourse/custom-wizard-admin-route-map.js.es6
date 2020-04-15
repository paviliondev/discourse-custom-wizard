export default {
  resource: 'admin',
  map() {
    this.route('adminWizards', { path: '/wizards', resetNamespace: true }, function() {
      
      this.route('adminWizardsWizard', { path: '/wizard/', resetNamespace: true }, function() {
        this.route('adminWizardsWizardShow', { path: '/:wizardId/', resetNamespace: true });
      });
      
      this.route('adminWizardsSubmissions', { path: '/submissions', resetNamespace: true }, function() {
        this.route('adminWizardsSubmissionsShow', { path: '/:wizardId/', resetNamespace: true });
      })
      
      this.route('adminWizardsApi', { path: '/api', resetNamespace: true }, function() {
        this.route('adminWizardsApiShow', { path: '/:name', resetNamespace: true });
      });
      
      this.route('adminWizardsLogs', { path: '/logs', resetNamespace: true });

      this.route('adminWizardsTransfer', { path: '/transfer', resetNamespace: true });
    });
  }
};
