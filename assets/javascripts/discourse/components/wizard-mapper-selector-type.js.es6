import discourseComputed from 'discourse-common/utils/decorators';
import Component from "@ember/component";

export default Component.extend({
  tagName: 'a',
  classNameBindings: ['active'],
  
  @discourseComputed('item.type', 'activeType')
  active(type, activeType) { return type === activeType },
  
  click() {
    this.toggle(this.item.type)
  }
})