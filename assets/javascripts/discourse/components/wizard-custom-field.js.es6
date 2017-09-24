import { observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-field',
  fieldTypes: ['dropdown', 'image', 'radio', 'text', 'textarea'],
  isDropdown: Ember.computed.equal('field.type', 'dropdown'),

  init() {
    this._super(...arguments);

    if (!this.get('field.choices')) {
      this.set('field.choices', Ember.A());
    }
  },

  @observes('field.label')
  setFieldId() {
    const label = this.get('field.label');
    this.set('field.id', Ember.String.underscore(label));
  },

  actions: {
    addChoice() {
      this.get('field.choices').pushObject(Ember.Object.create());
    }
  }
});
