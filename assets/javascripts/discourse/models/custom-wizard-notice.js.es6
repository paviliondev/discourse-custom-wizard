import EmberObject from "@ember/object";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { and, not, notEmpty } from "@ember/object/computed";
import { dasherize } from "@ember/string";
import I18n from "I18n";

const CustomWizardNotice = EmberObject.extend({
  expired: notEmpty("expired_at"),
  dismissed: notEmpty("dismissed_at"),
  hidden: notEmpty("hidden_at"),
  notHidden: not("hidden"),
  notDismissed: not("dismissed"),
  canDismiss: and("dismissable", "notDismissed"),
  canHide: and("can_hide", "notHidden"),

  @discourseComputed("type")
  typeClass(type) {
    return dasherize(type);
  },

  @discourseComputed("type")
  typeLabel(type) {
    return I18n.t(`admin.wizard.notice.type.${type}`);
  },

  dismiss() {
    if (!this.get("canDismiss")) {
      return;
    }

    return ajax(`/admin/wizards/notice/${this.get("id")}/dismiss`, {
      type: "PUT",
    })
      .then((result) => {
        if (result.success) {
          this.set("dismissed_at", result.dismissed_at);
        }
      })
      .catch(popupAjaxError);
  },

  hide() {
    if (!this.get("canHide")) {
      return;
    }

    return ajax(`/admin/wizards/notice/${this.get("id")}/hide`, { type: "PUT" })
      .then((result) => {
        if (result.success) {
          this.set("hidden_at", result.hidden_at);
        }
      })
      .catch(popupAjaxError);
  },
});

CustomWizardNotice.reopenClass({
  list(data = {}) {
    return ajax("/admin/wizards/notice", {
      type: "GET",
      data,
    }).catch(popupAjaxError);
  },

  dismissAll() {
    return ajax("/admin/wizards/notice/dismiss", {
      type: "PUT",
    }).catch(popupAjaxError);
  },
});

export default CustomWizardNotice;
