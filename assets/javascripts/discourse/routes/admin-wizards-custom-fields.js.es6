import DiscourseRoute from "discourse/routes/discourse";
import CustomWizardCustomField from "../models/custom-wizard-custom-field";
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardCustomField.listFields();
  },

  setupController(controller, model) {
    const customFields = A(model.custom_fields || []);
    const proSubscribed = model.pro_subscribed;

    controller.setProperties({
      customFields,
      proSubscribed
    });
  },
});
