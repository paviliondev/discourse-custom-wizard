import CustomWizardApi from '../models/custom-wizard-api';
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model(params) {
    if (params.name === 'create') {
      return CustomWizardApi.create({ isNew: true });
    } else {
      return CustomWizardApi.find(params.name);
    }
  },

  setupController(controller, model){
    controller.set("api", model);
  }
});
