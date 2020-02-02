import { default as computed, observes, on } from 'ember-addons/ember-computed-decorators';
import { generateSelectKitContent } from '../lib/custom-wizard';

export default Ember.Component.extend({
  classNames: 'wizard-custom-field',
  isDropdown: Ember.computed.equal('field.type', 'dropdown'),
  isUpload: Ember.computed.equal('field.type', 'upload'),
  isCategory: Ember.computed.equal('field.type', 'category'),
  disableId: Ember.computed.not('field.isNew'),
  choicesTypes: generateSelectKitContent(['translation', 'preset', 'custom']),
  choicesTranslation: Ember.computed.equal('field.choices_type', 'translation'),
  choicesPreset: Ember.computed.equal('field.choices_type', 'preset'),
  choicesCustom: Ember.computed.equal('field.choices_type', 'custom'),
  categoryPropertyTypes: generateSelectKitContent(['id', 'slug']),

  @computed('field.type')
  isInput: (type) => type === 'text' || type === 'textarea',

  @computed('field.type')
  isCategoryOrTag: (type) => type === 'tag' || type === 'category',

  @computed()
  presetChoices() {
    let presets = [
      {
        id: 'categories',
        name: I18n.t('admin.wizard.field.choices_preset.categories')
      },{
        id: 'groups',
        name: I18n.t('admin.wizard.field.choices_preset.groups')
      },{
        id: 'tags',
        name: I18n.t('admin.wizard.field.choices_preset.tags')
      }
    ];
    
    return presets;
  },

  @on('didInsertElement')
  @observes('isUpload')
  setupFileType() {
    if (this.get('isUpload') && !this.get('field.file_types')) {
      this.set('field.file_types', '.jpg,.png');
    }
  }
});
