import Controller from "@ember/controller";
import EmberObject from '@ember/object';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Controller.extend({
  fieldKeys: ['klass', 'type', 'serializers', 'name'],
  
  actions: {
    addField() {
      this.get('customFields').pushObject(
        EmberObject.create({
          new: true
        })
      );
    },
    
    removeField(field) {
      this.get('customFields').removeObject(field);
    },
    
    saveFields() {
      this.set('saving', true);
      ajax(`/admin/wizards/custom-fields`, {
        type: 'PUT',
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify({
          custom_fields: this.customFields
        })
      }).then(result => {
        if (result.success) {
          this.set('saveIcon', 'check');
        } else {
          this.set('saveIcon', 'times');
        }
        setTimeout(() => this.set('saveIcon', ''), 5000);
      }).finally(() => this.set('saving', false))
        .catch(popupAjaxError);
    }
  }
});