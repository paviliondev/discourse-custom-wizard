import Controller from "@ember/controller";
import { equal, or } from "@ember/object/computed";

export default Controller.extend({
  businessSubscription: equal("subscriptionType", "business"),
  communitySubscription: equal("subscriptionType", "community"),
  standardSubscription: equal("subscriptionType", "standard"),
  showApi: or("businessSubscription", "communitySubscription"),
});
