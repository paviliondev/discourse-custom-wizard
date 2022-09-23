import CustomWizardLogs from "../models/custom-wizard-logs";
import DiscourseRoute from "discourse/routes/discourse";
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model(params) {
    return CustomWizardLogs.list(params.wizardId);
  },

  setupController(controller, model) {
    controller.setProperties({
      wizard: model.wizard,
      logs: A(model.logs),
      total: model.total,
    });
  },
});
