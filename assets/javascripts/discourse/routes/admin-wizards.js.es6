import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default DiscourseRoute.extend({
  model() {
    return ajax("/admin/wizards");
  },

  setupController(controller, model) {
    controller.set("api_section", model.api_section);

    if (model.active_notice_count) {
      controller.set("activeNoticeCount", model.active_notice_count);
    }
    if (model.featured_notices) {
      controller.set("featuredNotices", model.featured_notices);
    }

    controller.subscribe();
  },

  afterModel(model, transition) {
    if (transition.targetName === "adminWizards.index") {
      this.transitionTo("adminWizardsWizard");
    }
  }
});
