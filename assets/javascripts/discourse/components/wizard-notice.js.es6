import Component from "@ember/component";
import NoticeMessage from "../mixins/notice-message";

export default Component.extend(NoticeMessage, {
  attributeBindings: ["notice.id:data-notice-id"],
  classNameBindings: [
    ":wizard-notice",
    "notice.typeClass",
    "notice.dismissed:dismissed",
    "notice.expired:expired",
    "notice.hidden:hidden",
  ],

  actions: {
    dismiss() {
      this.set("dismissing", true);
      this.notice.dismiss().then(() => {
        this.set("dismissing", false);
      });
    },

    hide() {
      this.set("hiding", true);
      this.notice.hide().then(() => {
        this.set("hiding", false);
      });
    },
  },
});
