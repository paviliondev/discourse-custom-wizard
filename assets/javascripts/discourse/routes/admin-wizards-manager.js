import DiscourseRoute from "discourse/routes/discourse";
import CustomWizardAdmin from "../models/custom-wizard-admin";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardAdmin.all();
  },

  setupController(controller, model) {
    controller.set("wizards", model);
  },
});
