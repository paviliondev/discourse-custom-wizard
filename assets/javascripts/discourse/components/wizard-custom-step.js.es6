import Component from "@ember/component";
import { default as discourseComputed } from 'discourse-common/utils/decorators';

export default Component.extend({
  classNames: 'wizard-custom-step',
  
  actions: {
    bannerUploadDone(upload) {
      this.set("step.banner", upload.url);
    },
    
    bannerUploadDeleted() {
      this.set("step.banner", null);
    }
  }
});
