import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import EmberObject from "@ember/object";
import { isEmpty } from "@ember/utils";

const CustomWizardCustomField = EmberObject.extend({
  isNew: isEmpty('id')
});

const basePath = '/admin/wizards/custom-fields';

CustomWizardCustomField.reopenClass({
  listFields() {
    return ajax(basePath).catch(popupAjaxError);
  },
  
  saveFields(customFields) {
    return ajax(basePath, {
      type: 'PUT',
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify({
        custom_fields: customFields
      })
    }).catch(popupAjaxError);
  },
  
  removeField(field) {
    return ajax(`${basePath}/${field.name}`, {
      type: 'DELETE'
    }).catch(popupAjaxError);
  }
});

export default CustomWizardCustomField;