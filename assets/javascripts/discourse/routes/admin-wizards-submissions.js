import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

export default DiscourseRoute.extend({
  router: service(),

  model() {
    return ajax(`/admin/wizards/wizard`);
  },

  setupController(controller, model) {
    const showParams = this.paramsFor("adminWizardsSubmissionsShow");

    controller.setProperties({
      wizardId: showParams.wizardId,
      wizardList: model.wizard_list,
    });
  },

  actions: {
    changeWizard(wizardId) {
      this.controllerFor("adminWizardsSubmissions").set("wizardId", wizardId);
      this.router.transitionTo("adminWizardsSubmissionsShow", wizardId);
    },
  },
});
