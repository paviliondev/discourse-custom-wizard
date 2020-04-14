import { default as discourseComputed, observes } from 'discourse-common/utils/decorators';
import { equal, or } from "@ember/object/computed";
import { selectKitContent, schema } from '../lib/wizard';
import Component from "@ember/component";

export default Component.extend({
  classNames: 'wizard-custom-field',
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
  
  // clearMapped only clears mapped fields if the field type of a specific field
  // changes, and not when switching between fields. Switching between fields also
  // changes the field.type property in this component
  
  @observes('field.id', 'field.type')
  clearMapped(ctx, changed) {    
    if (this.field.id === this.bufferedFieldId) {
      schema.field.mapped.forEach(property => {
        this.set(`field.${property}`, null);
      });
    }
    
    if (changed === 'field.type') {
      this.set('bufferedFieldId', this.field.id);
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
