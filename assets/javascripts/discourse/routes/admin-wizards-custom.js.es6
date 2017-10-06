import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model() {
    return CustomWizard.findAll();
  },

  afterModel(model, transition) {
    if (transition.intent.name !== 'adminWizard' && model.length > 0) {
      this.transitionTo('adminWizard', model[0].id);
    }
  },

  setupController(controller, model){
    controller.set("model", model.toArray());
  },

  actions: {
    willTransition(transition) {
      if (transition.intent.name === 'adminWizardsCustom') {
        this.refresh();
      }
    }
  }
});
