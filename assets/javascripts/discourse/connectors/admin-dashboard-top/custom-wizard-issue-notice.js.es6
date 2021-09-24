import { getOwner } from "discourse-common/lib/get-owner";

export default {
  setupComponent() {
    const controller = getOwner(this).lookup('controller:admin-dashboard')
    const wizardWarningNotice = controller.get('wizardWarningNotice');

    if (wizardWarningNotice) {
      this.set('wizardWarningNotice', wizardWarningNotice);
    }
  }
}