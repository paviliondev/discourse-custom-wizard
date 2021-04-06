import Component from "@ember/component";
import { default as discourseComputed } from "discourse-common/utils/decorators";

export default Component.extend({
  classNames: 'wizard-custom-step',

  @discourseComputed('step.index')
  stepConditionOptions(stepIndex) {
    const options = {
      inputTypes: 'validation',
      context: 'step',
      textSelection: 'value',
      userFieldSelection: true,
      groupSelection: true
    }

    if (stepIndex > 0) {
      options['wizardFieldSelection'] = true;
      options['wizardActionSelection'] = true;
    }

    return options;
  },

  actions: {
    bannerUploadDone(upload) {
      this.set("step.banner", upload.url);
    },

    bannerUploadDeleted() {
      this.set("step.banner", null);
    },
  },
});
