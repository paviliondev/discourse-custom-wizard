import Controller from "@ember/controller";
import { default as discourseComputed } from 'discourse-common/utils/decorators';
import { equal } from '@ember/object/computed';

export default Controller.extend({
  creating: equal('wizardId', 'create'),
  
  @discourseComputed('creating', 'wizardId')
  wizardListVal(creating, wizardId) {
    return creating ? null : wizardId;
  },
  
  @discourseComputed('creating', 'wizardId')
  message(creating, wizardId) {
    let type = 'select';
          
    if (creating) {
      type = 'create';
    } else if (wizardId) {
      type = 'edit';
    }
    
    return I18n.t(`admin.wizard.message.${type}`);  
  }
});