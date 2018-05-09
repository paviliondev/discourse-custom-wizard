export default Ember.Route.extend({
  beforeModel() {
    const appModel = this.modelFor('custom');
    if (appModel && appModel.permitted && !appModel.completed && appModel.start) {
      this.replaceWith('custom.step', appModel.start);
    }
  },

  model() {
    return this.modelFor('custom');
  },

  setupController(controller, model) {
    if (model) {
      const completed = model.get('completed');
      const permitted = model.get('permitted');
      const minTrust = model.get('min_trust');
      const wizardId = model.get('id');

      controller.setProperties({
        completed,
        notPermitted: !permitted,
        minTrust,
        wizardId
      });
    } else {
      controller.set('noWizard', true);
    }
  }
});
