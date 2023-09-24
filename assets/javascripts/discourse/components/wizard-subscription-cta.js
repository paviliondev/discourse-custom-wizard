import { inject as service } from "@ember/service";
import { action, computed } from "@ember/object";
import I18n from "I18n";
import Component from "@glimmer/component";

export default class WizardSubscriptionCta extends Component {
  @service subscription;

  @computed("subscription.subscribed")
  get i18nKey() {
    return `admin.wizard.subscription.cta.${
      this.subscription.subscribed ? "subscribed" : "none"
    }`;
  }

  @computed("subscription.subscribed")
  get icon() {
    return this.subscription.subscribed ? "far-life-ring" : "external-link-alt";
  }

  @computed("i18nKey")
  get title() {
    return I18n.t(`${this.i18nKey}.title`);
  }

  @computed("i18nKey")
  get label() {
    return I18n.t(`${this.i18nKey}.label`);
  }

  @action
  click() {
    window.open(this.subscription.subscriptionCtaLink, "_blank").focus();
  }
}
