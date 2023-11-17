import { inject as service } from "@ember/service";
import { action, computed } from "@ember/object";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import I18n from "I18n";

export default class WizardSubscriptionBadge extends Component {
  @service subscription;
  @tracked updating = false;
  @tracked updateIcon = "sync";
  basePath = "/admin/plugins/subscription-client";

  @computed("subscription.subscriptionType")
  get i18nKey() {
    return `admin.wizard.subscription.type.${
      this.subscription.subscriptionType
        ? this.subscription.subscriptionType
        : "none"
    }`;
  }

  @computed("i18nKey")
  get title() {
    return `${this.i18nKey}.title`;
  }

  @computed("i18nKey")
  get label() {
    return I18n.t(`${this.i18nKey}.label`);
  }

  @action
  click() {
    window.open(this.subscription.subscriptionCtaLink, "_blank").focus();
  }

  @action
  update() {
    this.updating = true;
    this.updateIcon = null;
    this.subscription.updateSubscriptionStatus().finally(() => {
      this.updateIcon = "sync";
      this.updating = false;
    });
  }
}
