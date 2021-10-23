import DiscourseRoute from "discourse/routes/discourse";
import CustomWizardCustomField from "../models/custom-wizard-custom-field";
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardCustomField.listFields();
  },

  setupController(controller, model) {
    const customFields = A(model.custom_fields || []);
    const subscribed = model.subscribed;
    const subscription = model.subscription;

    controller.setProperties({
      customFields,
      subscribed,
      subscription,
    });
  },
});
