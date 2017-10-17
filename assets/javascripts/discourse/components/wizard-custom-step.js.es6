export default Ember.Component.extend({
  classNames: 'wizard-custom-step',
  currentField: null,
  currentAction: null,
  disableId: Ember.computed.not('step.isNew')
});
