import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmberObject from "@ember/object";
import DiscourseURL from "discourse/lib/url";

const CustomWizardPro = EmberObject.extend();

const basePath = "/admin/wizards/pro";

CustomWizardPro.reopenClass({
  status() {
    return ajax(basePath, {
      type: "GET",
    }).catch(popupAjaxError);
  },

  authorize() {
    window.location.href = `${basePath}/authorize`;
  },

  unauthorize() {
    return ajax(`${basePath}/authorize`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },
  
  update_subscription() {
    return ajax(`${basePath}/subscription`, {
      type: "POST",
    }).catch(popupAjaxError);
  }
});

export default CustomWizardPro;