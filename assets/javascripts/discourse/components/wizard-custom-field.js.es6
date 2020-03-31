import { default as computed, observes, on } from 'discourse-common/utils/decorators';
import { equal, not, or } from "@ember/object/computed";
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
  isInput: (type) => type === 'text' || type === 'textarea' || type === 'url',

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
      wizardFieldSelection: true,
      userFieldSelection: true
    }
    
    if (isCategory || isGroup || isTag) {
      options.userFieldSelection = 'key,value';
      options[`${this.field.type}Selection`] = 'output';
    }
    
    return options;
  },
  
  prefillEnabled: or('isCategory', 'isTag', 'isGroup'),
  contentEnabled: or('isCategory', 'isTag', 'isGroup'),
  
  @computed('field.type')
  contentOptions(fieldType) {
    if (!this.contentEnabled) return {};
    
    let options = {
      hasOutput: true,
      enableConnectors: true,
      wizardFieldSelection: 'key,value',
      userFieldSelection: 'key,value',
      textDisabled: 'output'
    }

    options[`${this.field.type}Selection`] = 'output';
    options[`${this.field.type}AllowMultiple`] = true;
    
    return options;
  },
  
  actions: {
    imageUploadDone(upload) {
      this.set("field.image", upload.url);
    },
    
    imageUploadDeleted() {
      this.set("field.image", null);
    }
  }
});
