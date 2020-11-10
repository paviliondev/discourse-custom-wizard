import Controller from "@ember/controller";
import EmberObject from '@ember/object';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import CustomWizardCustomField from "../models/custom-wizard-custom-field";
import { default as discourseComputed } from 'discourse-common/utils/decorators';

export default Controller.extend({
  messageKey: 'create',
  fieldKeys: ['klass', 'type', 'serializers', 'name'],
  documentationUrl: "https://thepavilion.io/t/3572",
  
  actions: {
    addField() {
      this.get('customFields').pushObject(
        CustomWizardCustomField.create({ edit: true })
      );
    },
    
    saveField(field) {
      return CustomWizardCustomField.saveField(field)
        .then(result => {
          if (result.success) {
            this.setProperties({
              messageKey: 'saved',
              messageType: 'success'
            });
          } else {            
            if (result.messages) {
              this.setProperties({
                messageKey: 'error',
                messageType: 'error',
                messageOpts: { messages: result.messages }
              })
            }
          }
          
          setTimeout(() => this.setProperties({
            messageKey: 'create',
            messageType: null,
            messageOpts: null
          }), 10000);
          
          return result;
        });
    },
    
    removeField(field) {
      return CustomWizardCustomField.destroyField(field)
        .then(result => {
          this.get('customFields').removeObject(field);
        });
    }
  }
});