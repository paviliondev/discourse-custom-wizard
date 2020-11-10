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
  
  saveField(customField) {
    return ajax(basePath, {
      type: 'PUT',
      data: {
        custom_field: customField
      }
    }).catch(popupAjaxError);
  },
  
  destroyField(field) {
    return ajax(`${basePath}/${field.name}`, {
      type: 'DELETE'
    }).catch(popupAjaxError);
  }
});

export default CustomWizardCustomField;