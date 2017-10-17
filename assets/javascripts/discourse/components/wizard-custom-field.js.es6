import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-custom-field',
  isDropdown: Ember.computed.equal('field.type', 'dropdown'),

  @on('init')
  @observes('field')
  setup() {
    if (!this.get('isNew')) this.set('existingId', this.get('field.id'));
  },

  @computed('field.type')
  isInput: (type) => type === 'text' || type === 'textarea',

  @computed('field.choices.[]')
  dropdownChoices: choices => choices,

  @computed('field.choices_filters.[]')
  presetFilters: filters => filters,

  @computed()
  presetChoices() {
    return [
      { id: 'categories', name: I18n.t('admin.wizard.field.choices_preset.categories') }
    ];
  },

  actions: {
    addFilter() {
      if (!this.get('field.choices_filters')) {
        this.set('field.choices_filters', Ember.A());
      }
      this.get('field.choices_filters').pushObject(Ember.Object.create());
    },

    removeFilter(f) {
      this.get('field.choices_filters').removeObject(f);
    },

    addChoice() {
      if (!this.get('field.choices')) {
        this.set('field.choices', Ember.A());
      }
      this.get('field.choices').pushObject(Ember.Object.create());
    },

    removeChoice(c) {
      this.get('field.choices').removeObject(c);
    }
  }
});
