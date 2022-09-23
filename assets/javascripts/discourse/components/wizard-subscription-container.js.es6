import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import Subscription from "../mixins/subscription";

export default Component.extend(Subscription, {
  classNameBindings: [":wizard-subscription-container", "subscribed"],

  @discourseComputed("subscribed")
  subscribedIcon(subscribed) {
    return subscribed ? "check" : "dash";
  },

  @discourseComputed("subscribed")
  subscribedLabel(subscribed) {
    return `admin.wizard.subscription.${
      subscribed ? "subscribed" : "not_subscribed"
    }.label`;
  },

  @discourseComputed("subscribed")
  subscribedTitle(subscribed) {
    return `admin.wizard.subscription.${
      subscribed ? "subscribed" : "not_subscribed"
    }.title`;
  },
});
