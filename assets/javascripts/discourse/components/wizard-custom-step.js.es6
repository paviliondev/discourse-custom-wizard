import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-step',

  @computed('step.fields.@each.id')
  allowAddAction(stepFields) {
    console.log(stepFields)
    return stepFields.get('firstObject.id');
  },

  actions: {
    addField() {
      console.log('adding field')
      this.get('step.fields').pushObject(Ember.Object.create());
    },

    addAction() {
      this.get('step.actions').pushObject(Ember.Object.create());
    },

    removeStep() {
      this.sendAction('removeStep', this.get('step.name'));
    }
  }
});
