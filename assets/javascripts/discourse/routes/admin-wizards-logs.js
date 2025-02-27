import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  router: service(),

  model() {
    return ajax(`/admin/wizards/wizard`);
  },

  setupController(controller, model) {
    const showParams = this.paramsFor("adminWizardsLogsShow");

    controller.setProperties({
      wizardId: showParams.wizardId,
      wizardList: model.wizard_list,
    });
  },

  actions: {
    changeWizard(wizardId) {
      this.controllerFor("adminWizardsLogs").set("wizardId", wizardId);
      this.router.transitionTo("adminWizardsLogsShow", wizardId);
    },
  },
});
