import Component from "@ember/component";
import discourseComputed, { discourseObserve } from "discourse-common/utils/decorators";
import { or } from "@ember/object/computed";

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
  categorySerializers: ['basic_category', 'topic_view', 'topic_list_item'],
  klassContent: generateContent(['topic', 'post', 'group', 'category'], 'klass'),
  typeContent: generateContent(['string', 'boolean', 'json'], 'type'),
  showInputs: or('field.new', 'field.edit'),
  
  @discourseComputed('field.klass')
  serializerContent(klass) {
    const serializers = this.get(`${klass}Serializers`);
        
    if (serializers) {
      return generateContent(serializers, 'serializers');
    } else {
      return [];
    }
  },
  
  actions: {
    edit() {
      this.set('field.edit', true);
    },
    
    close() {
      if (this.field.edit) {
        this.set('field.edit', false);
      } else {
        this.removeField(this.field);
      }
    }
  }
});