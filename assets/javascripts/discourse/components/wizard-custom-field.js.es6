import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import { equal, not, or } from "@ember/object/computed";
import { selectKitContent } from '../lib/wizard';
import Component from "@ember/component";

export default Component.extend({
  classNames: 'wizard-custom-field',
  isDropdown: equal('field.type', 'dropdown'),
  isUpload: equal('field.type', 'upload'),
  isCategory: equal('field.type', 'category'),
  isGroup: equal('field.type', 'group'),
  isTag: equal('field.type', 'tag'),
  disableId: not('field.isNew'),
  categoryPropertyTypes: selectKitContent(['id', 'slug']),
  prefillEnabled: or('isCategory', 'isTag', 'isGroup', 'isDropdown'),
  contentEnabled: or('isCategory', 'isTag', 'isGroup', 'isDropdown'),

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
  
  setupTypeOutput(fieldType, options) {    
    const selectionType = {
      category: 'category',
      tag: 'tag',
      group: 'group'
    }[fieldType];
    
    if (selectionType) {
      options[`${selectionType}Selection`] = 'output';
      options.outputDefaultSelection = selectionType;
    }

    return options;
  },
  
  @discourseComputed('field.type')
  contentOptions(fieldType) {
    let options = {
      wizardFieldSelection: true,
      textSelection: 'key,value',
      userFieldSelection: 'key,value',
      context: 'field'
    }
    
    options = this.setupTypeOutput(fieldType, options);
    
    if (this.isDropdown) {
      options.wizardFieldSelection = 'key,value';
      options.listSelection += ',assignment';
      options.inputTypes = 'association,assignment';
      options.singular = true;
      options.pairConnector = 'association';
      options.keyPlaceholder = 'admin.wizard.key';
      options.valuePlaceholder = 'admin.wizard.value';
    }
        
    return options;
  },
  
  @discourseComputed('field.type')
  prefillOptions(fieldType) {
    let options = {
      wizardFieldSelection: true,
      textSelection: true,
      userFieldSelection: 'key,value',
      context: 'field'
    }

    return this.setupTypeOutput(fieldType, options);
  },
  
  @observes('field.type')
  clearInputs() {
    this.set('field.content', null);
    this.set('field.prefill', null);
  },
  
  @observes('isCategory')
  setupCategoryType() {
    if (this.isCategory && !this.field.property) {
      this.set('field.property', 'id');
    }
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
