import I18n from "I18n";

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

  setupController(controller, model) {
    let props = {
      step: model,
      wizard: this.modelFor('custom')
    };

    if (!model.permitted) {
      props['stepMessage'] = {
        state: 'not-permitted',
        text: model.permitted_message || I18n.t('wizard.step_not_permitted')
      };
      if (model.index > 0) {
        props['showReset'] = true;
      }
    }

    controller.setProperties(props);
  }
});
