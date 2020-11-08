import DiscourseRoute from "discourse/routes/discourse";
import CustomWizardCustomField from "../models/custom-wizard-custom-field";
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardCustomField.listFields();
  },
  
  setupController(controller, model) {
    const customFields = A(model || []);
    controller.set('customFields', customFields);
  }
});