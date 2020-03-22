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
        content.push(Ember.Object.create({
          id: a.code,
          label: "code (Route To)"
        }));
      }
    });

    return content;
  },

  @computed('step.id', 'wizard.save_submissions')
  wizardFields(currentStepId, saveSubmissions) {
    const allSteps = this.get('wizard.steps');
    let steps = allSteps;
    let fields = [];

    if (!saveSubmissions) {
      steps = [allSteps.findBy('id', currentStepId)];
    }

    steps.forEach((s) => {
      if (s.fields && s.fields.length > 0) {
        let stepFields = s.fields.map((f) => {
          return Ember.Object.create({
            id: f.id,
            label: `${f.id} (${s.id})`,
            type: f.type
          });
        });
        fields.push(...stepFields);
      }
    });

    return fields;
  },
});
