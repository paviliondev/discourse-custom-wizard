import CustomWizardLogs from "../models/custom-wizard-logs";
import DiscourseRoute from "discourse/routes/discourse";
import { A } from "@ember/array";
import { inject as service } from "@ember/service";

export default DiscourseRoute.extend({
  router: service(),

  model(params) {
    return CustomWizardLogs.list(params.wizardId);
  },

  afterModel(model) {
    if (model === null) {
      return this.router.transitionTo("adminWizardsLogs");
    }
  },

  setupController(controller, model) {
    controller.setProperties({
      wizard: model.wizard,
      logs: A(model.logs),
      total: model.total,
    });
  },
});
