import { A } from "@ember/array";
import CustomWizardAdmin from "../models/custom-wizard-admin";
import DiscourseRoute from "discourse/routes/discourse";
import { formatModel } from "../lib/wizard-submission";

export default DiscourseRoute.extend({
  model(params) {
    return CustomWizardAdmin.submissions(params.wizardId);
  },

  setupController(controller, model) {
    const { fields, submissions } = formatModel(model);

    controller.setProperties({
      wizard: model.wizard,
      fields: A(fields),
      submissions: A(submissions),
      total: model.total,
    });
  },
});
