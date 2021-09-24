import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model() {
    return ajax('/admin/wizards');
  },

  setupController(controller, model) {
    controller.set('notices', A(model.notices));
  },

  afterModel(model, transition) {
    if (transition.targetName === "adminWizards.index") {
      this.transitionTo("adminWizardsWizard");
    }
  }
});
