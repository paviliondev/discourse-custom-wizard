import { default as computed, observes, on } from 'discourse-common/utils/decorators';
import { equal, not } from "@ember/object/computed";
import { generateSelectKitContent } from '../lib/custom-wizard';

export default Ember.Component.extend({
  classNames: 'wizard-custom-field',
  isDropdown: equal('field.type', 'dropdown'),
  isUpload: equal('field.type', 'upload'),
  isCategory: equal('field.type', 'category'),
  isGroup: equal('field.type', 'group'),
  isTag: equal('field.type', 'tag'),
  disableId: not('field.isNew'),
  choicesTypes: generateSelectKitContent(['translation', 'custom']),
  choicesTranslation: equal('field.choices_type', 'translation'),
  choicesCustom: equal('field.choices_type', 'custom'),
  categoryPropertyTypes: generateSelectKitContent(['id', 'slug']),

  @computed('field.type')
  isInput: (type) => type === 'text' || type === 'textarea',

  @computed('field.type')
  isCategoryOrTag: (type) => type === 'tag' || type === 'category',

  @on('didInsertElement')
  @observes('isUpload')
  setupFileType() {
    if (this.get('isUpload') && !this.get('field.file_types')) {
      this.set('field.file_types', '.jpg,.png');
    }
  },
  
  @computed('isCategory', 'isGroup', 'isTag')
  prefillOptions(isCategory, isGroup, isTag) {
    let options = {
      hasOutput: true,
      enableConnectors: true,
      allowWizard: true,
      allowUser: true
    }
    
    if (isCategory) {
      options.allowUser = 'key,value';
      options.allowCategory = 'output';
    }
    
    if (isGroup) {
      options.allowUser = 'key,value';
      options.allowGroup = 'output';
    }
    
    if (isTag) {
      options.allowUser = 'key,value';
      options.allowTag = 'output';
    }
    
    return options;
  }
});
