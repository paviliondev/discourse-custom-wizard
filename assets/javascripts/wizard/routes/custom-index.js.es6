import { getCachedWizard } from "../models/custom";

export default Ember.Route.extend({
  beforeModel() {
    const wizard = getCachedWizard();
    if (wizard && wizard.permitted && !wizard.completed && wizard.start) {
      this.replaceWith("custom.step", wizard.start);
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

      controller.setProperties({
        requiresLogin: !user,
        user,
        name,
        completed,
        notPermitted: !permitted,
        wizardId,
      });
    } else {
      controller.set("noWizard", true);
    }
  },
});
