import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model() {
    return CustomWizard.findAllSubmissions();
  },

  setupController(controller, model){
    controller.set("model", model);
  }
});
