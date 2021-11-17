import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const CustomWizardNotice = EmberObject.extend();

CustomWizardNotice.reopen({
  dismiss() {
    return ajax(`/admin/wizards/notice/${this.id}`, { type: "PUT" })
      .then((result) => {
        if (result.success) {
          this.set("dismissed_at", result.dismissed_at);
        }
      })
      .catch(popupAjaxError);
  },
});

CustomWizardNotice.reopenClass({
  list() {
    return ajax("/admin/wizards/notice").catch(popupAjaxError);
  },
});

export default CustomWizardNotice;
