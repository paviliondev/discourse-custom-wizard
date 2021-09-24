import CustomWizardSubscription from "../models/custom-wizard-subscription";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardSubscription.status();
  },

  setupController(controller, model) {
    controller.set("model", model);
    controller.setup();
  },

  actions: {
    authorize() {
      CustomWizardSubscription.authorize();
    },
  },
});
