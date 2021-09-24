import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  classNameBindings: [":subscription-container", "subscribed"],

  @discourseComputed('subscribed')
  subscribedIcon(subscribed) {
    return subscribed ? 'check' : 'dash';
  },

  @discourseComputed('subscribed')
  subscribedLabel(subscribed) {
    return `admin.wizard.subscription_container.${subscribed ? 'subscribed' : 'not_subscribed'}.label`;
  },

  @discourseComputed('subscribed')
  subscribedTitle(subscribed) {
    return `admin.wizard.subscription_container.${subscribed ? 'subscribed' : 'not_subscribed'}.title`;
  }
})