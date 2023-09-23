import { inject as service } from "@ember/service";
import { action, computed } from "@ember/object";
import Component from '@glimmer/component';
import DiscourseURL from "discourse/lib/url";
import I18n from "I18n";

export default class WizardSubscriptionBadge extends Component {
  @service subscription;

  @computed("subscription.subscriptionType")
  get i18nKey() {
    return `admin.wizard.subscription.type.${this.subscription.subscriptionType ? this.subscription.subscriptionType : "none"}`;
  };

  @computed("i18nKey")
  get title() {
    return I18n.t(`${this.i18nKey}.title`);
  };

  @computed("i18nKey")
  get label() {
    return I18n.t(`${this.i18nKey}.label`);
  };

  @action
  click() {
    DiscourseURL.routeTo(this.subscription.subscriptionLink);
  };
};
