import { default as discourseComputed } from 'discourse-common/utils/decorators';
import { equal, or, alias } from "@ember/object/computed";
import { computed } from "@ember/object";
import { selectKitContent } from '../lib/wizard';
import UndoChanges from '../mixins/undo-changes';
import Component from "@ember/component";

export default Component.extend(UndoChanges, {
  componentType: 'field',
  classNameBindings: [':wizard-custom-field', 'visible'],
  visible: computed('currentFieldId', function() { return this.field.id === this.currentFieldId }),
  isDropdown: equal('field.type', 'dropdown'),
  isUpload: equal('field.type', 'upload'),
  isCategory: equal('field.type', 'category'),
  isGroup: equal('field.type', 'group'),
  isTag: equal('field.type', 'tag'),
  isText: equal('field.type', 'text'),
  isTextarea: equal('field.type', 'textarea'),
  isUrl: equal('field.type', 'url'),
  showPrefill: or('isCategory', 'isTag', 'isGroup', 'isDropdown'),
  showContent: or('isCategory', 'isTag', 'isGroup', 'isDropdown'),
  showLimit: or('isCategory', 'isTag'),
  showMinLength: or('isText', 'isTextarea', 'isUrl', 'isComposer'),
  categoryPropertyTypes: selectKitContent(['id', 'slug']),
  showAdvanced: alias('field.type'),
  messageUrl: 'https://thepavilion.io/t/2809',
  
  @discourseComputed('field.type')
  messageKey(type) {
    let key = 'type';
    if (type) {
      key = 'edit';
    }
    return key;
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
      options.userFieldOptionsSelection = 'output';
      options.textSelection = 'key,value,output';
      options.inputTypes = 'conditional,association,assignment';
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
  
  actions: {    
    imageUploadDone(upload) {
      this.set("field.image", upload.url);
    },
    
    imageUploadDeleted() {
      this.set("field.image", null);
    }
  }
});
