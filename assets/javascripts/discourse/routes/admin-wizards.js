import DiscourseRoute from "discourse/routes/discourse";
import { inject as service } from "@ember/service";

export default DiscourseRoute.extend({
  router: service(),

  afterModel(model, transition) {
    if (transition.targetName === "adminWizards.index") {
      this.router.transitionTo("adminWizardsWizard");
    }
  },
});
