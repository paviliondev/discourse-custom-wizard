import { A } from "@ember/array";
import DiscourseRoute from "discourse/routes/discourse";
import CustomWizardCustomField from "../models/custom-wizard-custom-field";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardCustomField.listFields();
  },

  setupController(controller, model) {
    const customFields = A(model.custom_fields || []);

    controller.setProperties({
      customFields,
    });
  },
});
