import { default as discourseComputed } from 'discourse-common/utils/decorators';
import Component from "@ember/component";

export default Component.extend({
  classNames: 'wizard-message',
  
  @discourseComputed('key', 'component')
  message(key, component) {
    return I18n.t(`admin.wizard.message.${component}.${key}`);
  },
  
  @discourseComputed('component')
  documentation(component) {
    return I18n.t(`admin.wizard.message.${component}.documentation`);
  }
})