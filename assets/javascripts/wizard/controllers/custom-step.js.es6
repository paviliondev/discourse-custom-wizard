import StepController from 'wizard/controllers/step';
import getUrl from 'discourse-common/lib/get-url';

export default StepController.extend({
  actions: {
    goNext(response) {
      const next = this.get('step.next');
      if (response.refresh_required) {
        const id = this.get('wizard.id');
        document.location = getUrl(`/wizard/custom/${id}/steps/${next}`);
      } else {
        this.transitionToRoute('custom.step', next);
      }
    },

    goBack() {
      this.transitionToRoute('custom.step', this.get('step.previous'));
    }
  }
});
