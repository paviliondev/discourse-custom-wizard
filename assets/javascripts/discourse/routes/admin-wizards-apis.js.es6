import CustomWizardApi from '../models/custom-wizard-api';

export default Discourse.Route.extend({
  model() {
    return CustomWizardApi.list();
  },

  setupController(controller, model){
    controller.set("model", model);
  }
});
