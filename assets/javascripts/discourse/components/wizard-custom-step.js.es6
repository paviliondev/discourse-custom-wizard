import Component from "@ember/component";
import { default as discourseComputed } from 'discourse-common/utils/decorators';
import { wizardFieldList } from '../lib/wizard';

export default Component.extend({
  classNames: 'wizard-custom-step',
  
  @discourseComputed('wizard.steps', 'step.id')
  descriptionWizardFields(steps, stepId) {
    return wizardFieldList(steps, { upTo: stepId });
  },
  
  actions: {
    bannerUploadDone(upload) {
      this.set("step.banner", upload.url);
    },
    
    bannerUploadDeleted() {
      this.set("step.banner", null);
    }
  }
});
