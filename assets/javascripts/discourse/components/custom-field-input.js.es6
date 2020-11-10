import Component from "@ember/component";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import { or, alias } from "@ember/object/computed";

const generateContent = function(array, type) {
  return array.map(key => ({
    id: key,
    name: I18n.t(`admin.wizard.custom_field.${type}.${key}`)
  }));
}

export default Component.extend({
  tagName: 'tr',
  topicSerializers: ['topic_view', 'topic_list_item'],
  postSerializers: ['post'],
  groupSerializers: ['basic_group'],
  categorySerializers: ['basic_category'],
  klassContent: generateContent(['topic', 'post', 'group', 'category'], 'klass'),
  typeContent: generateContent(['string', 'boolean', 'integer', 'json'], 'type'),
  showInputs: or('field.new', 'field.edit'),
  classNames: ['custom-field-input'],
  loading: or('saving', 'destroying'),
  destroyDisabled: alias('loading'),
  closeDisabled: alias('loading'),
  
  didInsertElement() {
    this.set('originalField', JSON.parse(JSON.stringify(this.field)));
  },
  
  @discourseComputed('field.klass')
  serializerContent(klass, p2) {
    const serializers = this.get(`${klass}Serializers`);
    
    if (serializers) {
      return generateContent(serializers, 'serializers');
    } else {
      return [];
    }
  },
  
  @observes('field.klass')
  clearSerializersWhenClassChanges() {
    this.set('field.serializers', null);
  },
  
  compareArrays(array1, array2) {
    return array1.length === array2.length && array1.every((value, index) => {
      return value === array2[index];
    });
  },
  
  @discourseComputed(
    'saving',
    'field.name',
    'field.klass',
    'field.type',
    'field.serializers'
  )
  saveDisabled(saving) {
    if (saving) return true;
    
    const originalField = this.originalField;
    if (!originalField) return false;
        
    return ['name', 'klass', 'type', 'serializers'].every(attr => {
      let current = this.get(attr);
      let original = originalField[attr];
      
      if (!current) return false;
      
      if (attr == 'serializers') {
        return this.compareArrays(current, original);
      } else {
        return current == original;
      }
    });
  },
  
  actions: {
    edit() {
      this.set('field.edit', true);
    },
    
    close() {
      if (this.field.edit) {
        this.set('field.edit', false);
      }
    },
    
    destroy() {
      this.set('destroying', true);
      this.removeField(this.field);
    },
    
    save() {
      this.set('saving', true);
      
      const field = this.field;
      
      let data = {
        id: field.id,
        klass: field.klass,
        type: field.type,
        serializers: field.serializers,
        name: field.name
      }
      
      this.saveField(data).then((result) => {
        this.set('saving', false);
        if (result.success) {
          this.set('field.edit', false);
        } else {
          this.set('saveIcon', 'times');
        }
        setTimeout(() => this.set('saveIcon', null), 10000);
      });
    }
  }
});