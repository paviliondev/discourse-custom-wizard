import StepController from "wizard/controllers/step";
import getUrl from "discourse-common/lib/get-url";

export default StepController.extend({
  actions: {
    goNext(response) {
      let nextStepId = response["next_step_id"];

      if (response.redirect_on_next) {
        window.location.href = response.redirect_on_next;
      } else if (response.refresh_required) {
        const wizardId = this.get("wizard.id");
        window.location.href = getUrl(`/w/${wizardId}/steps/${nextStepId}`);
      } else {
        this.transitionToRoute("custom.step", nextStepId);
      }
    },

    goBack() {
      this.transitionToRoute("custom.step", this.get("step.previous"));
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
