import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model() {
    return CustomWizard.all();
  },

  afterModel(model, transition) {
    if (transition.intent.name !== 'adminWizardSubmissions' && model.length > 0) {
      this.transitionTo('adminWizardSubmissions', model[0].id);
    }
  },

  setupController(controller, model){
    controller.set("model", model);
  }
});
