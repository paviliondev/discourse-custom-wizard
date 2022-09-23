import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import Subscription from "../mixins/subscription";
import I18n from "I18n";

export default Component.extend(Subscription, {
  tagName: "a",
  classNameBindings: [":btn", ":btn-pavilion-support", "subscriptionType"],
  attributeBindings: ["title"],

  @discourseComputed("subscribed")
  i18nKey(subscribed) {
    return `admin.wizard.subscription.cta.${
      subscribed ? "subscribed" : "none"
    }`;
  },

  @discourseComputed("subscribed")
  icon(subscribed) {
    return subscribed ? "far-life-ring" : "external-link-alt";
  },

  @discourseComputed("i18nKey")
  title(i18nKey) {
    return I18n.t(`${i18nKey}.title`);
  },

  @discourseComputed("i18nKey")
  label(i18nKey) {
    return I18n.t(`${i18nKey}.label`);
  },

  click() {
    window.open(this.subscriptionCtaLink, "_blank").focus();
  },
});
