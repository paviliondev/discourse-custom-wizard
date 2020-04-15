import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import EmberObject from "@ember/object";

const CustomWizardLogs = EmberObject.extend();

CustomWizardLogs.reopenClass({
  list(page = 0) {
    return ajax('/admin/wizards/logs', {
      data: {
        page
      }
    }).catch(popupAjaxError);
  }
});

export default CustomWizardLogs;