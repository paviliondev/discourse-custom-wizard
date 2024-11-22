import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  router: service(),

  afterModel(model, transition) {
    if (transition.targetName === "adminWizards.index") {
      this.router.transitionTo("adminWizardsWizard");
    }
  },
});
