import { observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-step',
  currentField: null,
  currentAction: null,
  disableId: Ember.computed.not('step.isNew'),

  @observes('step')
  resetCurrentObjects() {
    const fields = this.get('step.fields');
    const actions = this.get('step.actions');
    this.setProperties({
      currentField: fields.length ? fields[0] : null,
      currentAction: actions.length ? actions[0] : null
    });
  }
});
