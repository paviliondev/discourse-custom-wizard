import Component from "@ember/component";
import CustomWizardPro from "../models/custom-wizard-pro";
import { notEmpty } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  classNameBindings: [
    ":custom-wizard-pro-subscription",
    "subscription.active:active:inactive",
  ],
  subscribed: notEmpty("subscription"),

  @discourseComputed("subscription.type")
  title(type) {
    return type
      ? I18n.t(`admin.wizard.pro.subscription.title.${type}`)
      : I18n.t("admin.wizard.pro.not_subscribed");
  },

  @discourseComputed("subscription.active")
  stateClass(active) {
    return active ? "active" : "inactive";
  },

  @discourseComputed("stateClass")
  stateLabel(stateClass) {
    return I18n.t(`admin.wizard.pro.subscription.status.${stateClass}`);
  },

  actions: {
    update() {
      this.set("updating", true);
      CustomWizardPro.update_subscription()
        .then((result) => {
          if (result.success) {
            this.setProperties({
              updateIcon: "check",
              subscription: result.subscription,
            });
          } else {
            this.set("updateIcon", "times");
          }
        })
        .finally(() => {
          this.set("updating", false);
          setTimeout(() => {
            this.set("updateIcon", null);
          }, 7000);
        });
    },
  },
});
