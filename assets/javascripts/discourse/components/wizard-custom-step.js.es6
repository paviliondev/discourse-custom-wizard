import { observes, on, default as discourseComputed } from 'discourse-common/utils/decorators';
import { not } from "@ember/object/computed";
import EmberObject from "@ember/object";
import Component from "@ember/component";

export default Component.extend({
  classNames: 'wizard-custom-step',
  disableId: not('step.isNew'),

  @discourseComputed('wizardFields', 'wizard.steps')
  requiredContent(wizardFields, steps) {
    let content = wizardFields;
    let actions = [];

    steps.forEach(s => {
      actions.push(...s.actions);
    });

    actions.forEach(a => {
      if (a.type === 'route_to' && a.code) {
        content.push(
          EmberObject.create({
            id: a.code,
            label: "code (Route To)"
          })
        );
      }
    });

    return content;
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
