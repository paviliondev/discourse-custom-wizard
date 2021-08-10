import CustomWizardPro from "../models/custom-wizard-pro";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardPro.status();
  },

  setupController(controller, model) {
    console.log(model)
    controller.set('model', model);
    controller.setup();
  },

  actions: {
    authorize() {
      CustomWizardPro.authorize();
    }
  }
});
