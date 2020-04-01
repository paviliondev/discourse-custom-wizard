import { observes, on, default as discourseComputed } from 'discourse-common/utils/decorators';
import { not } from "@ember/object/computed";

export default Ember.Component.extend({
  classNames: 'wizard-custom-step',
  currentField: null,
  currentAction: null,
  disableId: not('step.isNew'),
  
  @on('didInsertElement')
  @observes('step')
  resetCurrentObjects() {
    const fields = this.step.fields;
    const actions = this.step.actions;
    
    this.setProperties({
      currentField: fields.length ? fields[0] : null,
      currentAction: actions.length ? actions[0] : null
    });
  },

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
          Ember.Object.create({
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
