import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { not, notEmpty } from "@ember/object/computed";
import I18n from "I18n";

export default Component.extend({
  classNameBindings: [':wizard-notice', 'notice.type', 'dismissed', 'expired', 'resolved'],
  showFull: false,
  resolved: notEmpty('notice.expired_at'),
  dismissed: notEmpty('notice.dismissed_at'),
  canDismiss: not('dismissed'),

  @discourseComputed('notice.type')
  title(type) {
    return I18n.t(`admin.wizard.notice.title.${type}`);
  },

  @discourseComputed('notice.type')
  icon(type) {
    return {
      plugin_status_warning: 'exclamation-circle',
      plugin_status_connection_error: 'bolt',
      subscription_messages_connection_error: 'bolt',
      info: 'info-circle'
    }[type];
  },

  actions: {
    dismiss() {
      this.set('dismissing', true);
      this.notice.dismiss().then(() => {
        this.set('dismissing', false);
      });
    }
  }
});