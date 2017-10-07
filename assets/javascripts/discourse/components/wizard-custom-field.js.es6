import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-field',
  isDropdown: Ember.computed.equal('field.type', 'dropdown'),

  @on('init')
  @observes('field.id')
  init() {
    this._super(...arguments);
    if (!this.get('field.choices')) {
      this.set('field.choices', Ember.A());
    }
  },

  @computed('field.choices.[]')
  dropdownChoices: choices => choices,

  actions: {
    addChoice() {
      this.get('field.choices').pushObject(Ember.Object.create());
    },

    removeChoice(c) {
      this.get('field.choices').removeObject(c);
    }
  }
});
