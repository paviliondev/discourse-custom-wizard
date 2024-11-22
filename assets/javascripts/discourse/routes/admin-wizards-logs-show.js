import { A } from "@ember/array";
import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";
import CustomWizardLogs from "../models/custom-wizard-logs";

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
