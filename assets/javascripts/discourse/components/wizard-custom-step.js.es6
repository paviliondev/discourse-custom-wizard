import { 
  observes,
  on,
  default as computed
} from 'discourse-common/utils/decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-step',
  currentField: null,
  currentAction: null,
  disableId: Ember.computed.not('step.isNew'),
  
  @on('didInsertElement')
  @observes('step')
  resetCurrentObjects() {
    const fields = this.get('step.fields');
    const actions = this.get('step.actions');
    this.setProperties({
      currentField: fields.length ? fields[0] : null,
      currentAction: actions.length ? actions[0] : null
    });
  },

  @computed('wizardFields', 'wizard.steps')
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
