import CustomWizardApi from "../models/custom-wizard-api";
import DiscourseRoute from "discourse/routes/discourse";
import { inject as service } from "@ember/service";

export default DiscourseRoute.extend({
  router: service(),

  model(params) {
    if (params.name === "create") {
      return CustomWizardApi.create({ isNew: true });
    } else {
      return CustomWizardApi.find(params.name);
    }
  },

  afterModel(model) {
    if (model === null) {
      return this.router.transitionTo("adminWizardsApi");
    }
  },

  setupController(controller, model) {
    controller.set("api", model);
  },
});
