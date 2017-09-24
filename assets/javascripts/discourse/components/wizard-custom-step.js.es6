import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-step',

  @computed('step.fields.@each.id')
  allowAddAction(stepFields) {
    return stepFields.get('firstObject.id');
  },

  actions: {
    addField() {
      this.get('step.fields').pushObject(Ember.Object.create());
    },

    addAction() {
      this.get('step.actions').pushObject(Ember.Object.create());
    },

    removeField(field) {
      this.get('step.fields').removeObject(field);
    }
  }
});
