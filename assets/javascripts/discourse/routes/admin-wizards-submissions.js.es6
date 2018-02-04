import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model() {
    return CustomWizard.all();
  },

  afterModel(model, transition) {
    if (transition.intent.name !== 'adminWizardSubmissions' && model[0] && model[0].id) {
      this.transitionTo('adminWizardSubmissions', model[0].id);
    }
  },

  setupController(controller, model){
    controller.set("model", model);
  }
});
