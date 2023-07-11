import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import Subscription from "../mixins/subscription";
import DiscourseURL from "discourse/lib/url";
import I18n from "I18n";

export default Component.extend(Subscription, {
  tagName: "a",
  classNameBindings: [":wizard-subscription-badge", "subscriptionType"],
  attributeBindings: ["title"],

  @discourseComputed("subscriptionType")
  i18nKey(type) {
    return `admin.wizard.subscription.type.${type ? type : "none"}`;
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
    DiscourseURL.routeTo(this.subscriptionLink);
  },
});
