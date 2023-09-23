import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { inject as service } from "@ember/service";

export default Component.extend({
  classNameBindings: [":wizard-subscription-container", "subscribed"],
  subscription: service(),

  @discourseComputed("subscription.subscribed")
  subscribedIcon(subscribed) {
    return subscribed ? "check" : "times";
  },

  @discourseComputed("subscription.subscribed")
  subscribedLabel(subscribed) {
    return `admin.wizard.subscription.${
      subscribed ? "subscribed" : "not_subscribed"
    }.label`;
  },

  @discourseComputed("subscription.subscribed")
  subscribedTitle(subscribed) {
    return `admin.wizard.subscription.${
      subscribed ? "subscribed" : "not_subscribed"
    }.title`;
  },
});
