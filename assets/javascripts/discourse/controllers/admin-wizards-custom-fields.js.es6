import Controller from "@ember/controller";
import EmberObject from '@ember/object';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import CustomWizardCustomField from "../models/custom-wizard-custom-field";

export default Controller.extend({
  fieldKeys: ['klass', 'type', 'serializers', 'name'],
  documentationUrl: "https://thepavilion.io/t/3572",
  
  actions: {
    addField() {
      this.get('customFields').pushObject(
        CustomWizardCustomField.create()
      );
    },
    
    removeField(field) {
      this.get('customFields').removeObject(field);
    },
    
    saveFields() {
      this.set('saving', true);
      CustomWizardCustomField.saveFields(this.customFields)
        .then(result => {
          if (result.success) {
            this.set('saveIcon', 'check');
          } else {
            this.set('saveIcon', 'times');
          }
          setTimeout(() => this.set('saveIcon', ''), 5000);
        }).finally(() => {
          this.set('saving', false);
        });
    }
  }
});