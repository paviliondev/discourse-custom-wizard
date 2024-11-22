import CustomWizardAdmin from "../models/custom-wizard-admin";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardAdmin.all();
  },

  setupController(controller, model) {
    controller.set("wizards", model);
  },
});
