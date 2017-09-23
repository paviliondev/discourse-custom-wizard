import { observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-field',
  fieldTypes: ['dropdown', 'image', 'radio', 'text', 'textarea'],
  isDropdown: Ember.computed.equal('field.type', 'dropdown'),
  choices: Ember.A(),

  @observes('field.label')
  setFieldId() {
    const label = this.get('field.label');
    console.log('setting id')
    this.set('field.id', Ember.String.underscore(label));
  },

  actions: {
    addChoice() {

    }
  }
});
