import discourseComputed from 'discourse-common/utils/decorators';
import { snakeCase } from '../lib/wizard';
import { selectionTypes } from '../lib/wizard-mapper';
import Component from "@ember/component";

export default Component.extend({
  tagName: 'a',
  classNameBindings: ['type', 'active'],
  
  @discourseComputed('type', 'activeType')
  active(type, activeType) { return type === activeType },
  
  @discourseComputed('type')
  label(type) { return I18n.t(`admin.wizard.selector.label.${snakeCase(type)}`) },
  
  click() {
    this.toggle(this.type)
  }
})