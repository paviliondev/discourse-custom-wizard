import Component from "@glimmer/component";
import { computed } from "@ember/object";
import { service } from "@ember/service";

export default class WizardSubscriptionContainer extends Component {
  @service subscription;

  @computed("subscription.subscribed")
  get subscribedIcon() {
    return this.subscription.subscribed ? "check" : "xmark";
  }

  @computed("subscription.subscribed")
  get subscribedLabel() {
    return `admin.wizard.subscription.${
      this.subscription.subscribed ? "subscribed" : "not_subscribed"
    }.label`;
  }

  @computed("subscription.subscribed")
  get subscribedTitle() {
    return `admin.wizard.subscription.${
      this.subscription.subscribed ? "subscribed" : "not_subscribed"
    }.title`;
  }
}
