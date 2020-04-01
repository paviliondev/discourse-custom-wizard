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
      const wizardId = model.get('id');
      const user = model.get('user');
      const name = model.get('name');

      controller.setProperties({
        requiresLogin: !user,
        user,
        name,
        completed,
        notPermitted: !permitted,
        wizardId
      });
    } else {
      controller.set('noWizard', true);
    }
  }
});
