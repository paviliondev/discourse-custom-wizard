import Controller from "@ember/controller";
import EmberObject from '@ember/object';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Controller.extend({
  fieldKeys: ['klass', 'name', 'type'],
  classes: ['topic', 'user', 'group'],
  
  actions: {
    addField() {
      this.get('customFields').pushObject(
        EmberObject.create({
          new: true
        })
      );
    },
    
    saveFields() {      
      ajax(`/admin/wizards/custom-fields`, {
        type: 'PUT',
        data: {
          custom_fields: this.customFields
        }
      }).catch(popupAjaxError)
    }
  }
});