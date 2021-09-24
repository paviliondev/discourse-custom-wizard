import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmberObject from "@ember/object";

const CustomWizardSubscription = EmberObject.extend();

const basePath = "/admin/wizards/subscription";

CustomWizardSubscription.reopenClass({
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

  update() {
    return ajax(basePath, {
      type: "POST",
    }).catch(popupAjaxError);
  },
});

export default CustomWizardSubscription;
