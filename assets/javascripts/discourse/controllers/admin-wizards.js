import Controller from "@ember/controller";
import { or } from "@ember/object/computed";
import { inject as service } from "@ember/service";

export default Controller.extend({
  subscription: service(),

  showApi: or(
    "subscription.businessSubscription",
    "subscription.communitySubscription"
  ),
});
