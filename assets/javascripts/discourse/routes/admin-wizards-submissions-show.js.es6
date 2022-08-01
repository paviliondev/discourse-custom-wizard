import { A } from "@ember/array";
import EmberObject from "@ember/object";
import CustomWizardAdmin from "../models/custom-wizard-admin";
import DiscourseRoute from "discourse/routes/discourse";
import CustomWizard from "../models/custom-wizard";

export default DiscourseRoute.extend({
  model(params) {
    return CustomWizardAdmin.submissions(params.wizardId);
  },

  setupController(controller, model) {
    const fields = model.fields.map((f) => {
      const fieldsObject = EmberObject.create(f);
      fieldsObject.enabled = true;
      return fieldsObject;
    });
    controller.setProperties({
      wizard: model.wizard,
      fields: A(fields),
      submissions: A(model.submissions),
      total: model.total,
    });
  },
});
