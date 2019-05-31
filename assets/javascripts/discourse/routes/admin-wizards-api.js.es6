import CustomWizardApi from '../models/custom-wizard-api';

export default Discourse.Route.extend({
  model(params) {
    if (params.service === 'new') {
      return {};
    } else {
      return CustomWizardApi.find(params.service);
    }
  },

  setupController(controller, model){
    controller.set("api", model);
  }
});
