export default Ember.Route.extend({
  beforeModel() {
    const appModel = this.modelFor('custom');
    if (appModel.permitted && !appModel.completed && appModel.start) {
      this.replaceWith('custom.step', appModel.start);
    }
  },

  model() {
    return this.modelFor('custom');
  },

  setupController(controller, model) {
    const completed = model.get('completed');
    const permitted = model.get('permitted');
    const minTrust = model.get('min_trust');
    controller.setProperties({
      completed,
      notPermitted: !permitted,
      minTrust
    });
  }
});
