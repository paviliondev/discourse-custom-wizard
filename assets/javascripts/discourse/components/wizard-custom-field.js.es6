import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import { equal, not, or } from "@ember/object/computed";
import { generateSelectKitContent } from '../lib/wizard';

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
  prefillEnabled: or('isCategory', 'isTag', 'isGroup'),
  contentEnabled: or('isCategory', 'isTag', 'isGroup'),
  hasAdvanced: or('isCategory', 'isTag', 'isGroup'),

  @discourseComputed('field.type')
  isInput: (type) => type === 'text' || type === 'textarea' || type === 'url',

  @discourseComputed('field.type')
  isCategoryOrTag: (type) => type === 'tag' || type === 'category',

  @on('didInsertElement')
  @observes('isUpload')
  setupFileType() {
    if (this.isUpload && !this.field.file_types) {
      this.set('field.file_types', '.jpg,.png');
    }
  },
  
  @discourseComputed('field.type')
  prefillOptions(fieldType) {
    if (!this.prefillEnabled) return {};
    
    let options = {
      hasOutput: true,
      textSelection: 'key,value',
      wizardSelection: true,
      userSelection: 'key,value'
    }

    options[`${fieldType}Selection`] = 'output';
    options[`outputDefaultSelection`] = fieldType;
    
    return options;
  },
  
  @discourseComputed('field.type')
  contentOptions(fieldType) {
    if (!this.contentEnabled) return {};
    
    let options = {
      hasOutput: true,
      wizardSelection: 'key,value',
      userSelection: 'key,value',
      textSelection: 'key,value'
    }

    options[`${fieldType}Selection`] = 'output';
    
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
