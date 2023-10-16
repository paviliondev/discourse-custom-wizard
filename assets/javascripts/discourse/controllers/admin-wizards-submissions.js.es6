import Controller from "@ember/controller";
import { default as discourseComputed } from "discourse-common/utils/decorators";

export default Controller.extend({
  documentationUrl:
    "https://pavilion.tech/products/discourse-custom-wizard-plugin/documentation/",

  @discourseComputed("wizardId")
  wizardName(wizardId) {
    let currentWizard = this.wizardList.find(
      (wizard) => wizard.id === wizardId
    );
    if (currentWizard) {
      return currentWizard.name;
    }
  },

  @discourseComputed("wizardName")
  messageOpts(wizardName) {
    return {
      wizardName,
    };
  },

  @discourseComputed("wizardId")
  messageKey(wizardId) {
    let key = "select";

    if (wizardId) {
      key = "viewing";
    }

    return key;
  },
});
