import Controller from "@ember/controller";
import { equal } from "@ember/object/computed";

export default Controller.extend({
  businessSubscription: equal("subscriptionType", "business"),
  standardSubscription: equal("subscriptionType", "standard"),
});
