export default {
  resource: 'admin',
  map() {
    this.route('adminWizards', { path: '/wizards', resetNamespace: true }, function() {
      this.route('adminWizardsCustom', { path: '/custom', resetNamespace: true }, function() {
        this.route('adminWizard', { path: '/:name', resetNamespace: true });
      });
    });
  }
};
