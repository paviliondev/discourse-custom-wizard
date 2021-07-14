import CustomWizard from "../models/custom-wizard";
import DiscourseRoute from "discourse/routes/discourse";
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model(params) {
    return CustomWizard.submissions(params.wizardId);
  },

  setupController(controller, model) {
    controller.setProperties({
      wizard: model.wizard,
      fields: model.fields,
      submissions: A(model.submissions),
      total: model.total
    });
  },
});
