import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import EmberObject from "@ember/object";

const CustomWizardManager = EmberObject.extend();

const basePath = "admin/wizards/manager";

CustomWizardManager.reopenClass({
  import($formData) {
    return ajax(`/${basePath}/import`, {
      type: 'POST',
      data: $formData,
      processData: false,
      contentType: false,
    }).catch(popupAjaxError);
  },
  
  export(wizardIds) {
    let url = `${Discourse.BaseUrl}/${basePath}/export?`;
    
    wizardIds.forEach((wizardId, index) => {
      let step = 'wizard_ids[]=' + wizardId;
      if (index !== wizardIds[wizardIds.length - 1]) {
        step += '&';
      }
      url += step;
    });

    location.href = url;
  },
  
  destroy(wizardIds) {
    return ajax(`/${basePath}/destroy`, {
      type: "DELETE",
      data: {
        wizard_ids: wizardIds
      }
    }).catch(popupAjaxError);
  }
});

export default CustomWizardManager;