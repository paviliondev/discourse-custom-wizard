import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

export default DiscourseRoute.extend({
  router: service(),

  model() {
    return ajax("/admin/wizards");
  },

  setupController(controller, model) {
    controller.setProperties({
      subscribed: model.subscribed,
      subscriptionType: model.subscription_type,
      subscriptionAttributes: model.subscription_attributes,
      subscriptionClientInstalled: model.subscription_client_installed,
    });
  },

  afterModel(model, transition) {
    if (transition.targetName === "adminWizards.index") {
      this.router.transitionTo("adminWizardsWizard");
    }
  },
});
