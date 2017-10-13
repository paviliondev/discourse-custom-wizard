export default Ember.Route.extend({
  model(params) {
    const appModel = this.modelFor('custom');
    const allSteps = appModel.steps;
    if (allSteps) {
      const step = allSteps.findBy('id', params.step_id);
      return step ? step : allSteps[0];
    };

    return appModel;
  },

  afterModel(model) {
    if (model.completed) return this.transitionTo('index');
    return model.set("wizardId", this.modelFor('custom').id);
  },

  setupController(controller, step) {
    controller.setProperties({
      step, wizard: this.modelFor('custom')
    });
  }
});
