import Controller from "@ember/controller";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";

export default Controller.extend({
  actions: {
    dismissNotice(noticeId) {
      ajax(`/admin/wizards/notice/${this.id}`, {
        type: "DELETE",
      })
        .then((result) => {
          if (result.success) {
            const notices = this.notices;
            notices.removeObject(notices.findBy("id", noticeId));
          }
        })
        .catch(popupAjaxError);
    },
  },
});
