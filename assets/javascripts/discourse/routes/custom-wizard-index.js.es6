import { getCachedWizard } from "../models/custom-wizard";
import Route from "@ember/routing/route";

export default Route.extend({
  beforeModel() {
    const wizard = getCachedWizard();
    if (
      wizard &&
      wizard.user &&
      wizard.permitted &&
      !wizard.completed &&
      wizard.start
    ) {
      this.replaceWith("customWizardStep", wizard.start);
    }
  },

  model() {
    return getCachedWizard();
  },

  setupController(controller, model) {
    if (model && model.id) {
      const completed = model.get("completed");
      const permitted = model.get("permitted");
      const wizardId = model.get("id");
      const user = model.get("user");
      const name = model.get("name");
      const requiresLogin = !user;
      const notPermitted = !permitted;

      const props = {
        requiresLogin,
        user,
        name,
        completed,
        notPermitted,
        wizardId,
      };
      controller.setProperties(props);
    } else {
      controller.set("noWizard", true);
    }
  },
});
