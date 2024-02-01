import Controller from "@ember/controller";
import getUrl from "discourse-common/lib/get-url";
import { inject as service } from "@ember/service";

export default Controller.extend({
  router: service(),
  wizard: null,
  step: null,

  actions: {
    goNext(response) {
      let nextStepId = response["next_step_id"];

      if (response.redirect_on_next) {
        window.location.href = response.redirect_on_next;
      } else if (response.refresh_required) {
        const wizardId = this.get("wizard.id");
        window.location.href = getUrl(`/w/${wizardId}/steps/${nextStepId}`);
      } else {
        this.router.transitionTo("customWizardStep", nextStepId);
      }
    },

    goBack() {
      this.router.transitionTo("customWizardStep", this.get("step.previous"));
    },

    showMessage(message) {
      this.set("stepMessage", message);
    },

    resetWizard() {
      const id = this.get("wizard.id");
      const stepId = this.get("step.id");
      window.location.href = getUrl(`/w/${id}/steps/${stepId}?reset=true`);
    },
  },
});
