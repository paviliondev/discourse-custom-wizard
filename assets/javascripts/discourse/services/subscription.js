import Service from '@ember/service';
import { getOwner } from "discourse-common/lib/get-owner";

const PRODUCT_PAGE = "https://custom-wizard.pavilion.tech";
const SUPPORT_MESSAGE =
  "https://coop.pavilion.tech/new-message?username=support&title=Custom%20Wizard%20Support";
const MANAGER_CATEGORY =
  "https://discourse.pluginmanager.org/c/discourse-custom-wizard";

export default class SubscriptionService extends Service {
    subscriptionLandingUrl = PRODUCT_PAGE;
    subscribed = this.adminWizards.subscribed;
    subscriptionType = this.adminWizards.subscriptionType;
    businessSubscription = this.adminWizards.businessSubscription;
    communitySubscription = this.adminWizards.communitySubscription;
    standardSubscription = this.adminWizards.standardSubscription;
    subscriptionAttributes = this.adminWizards.subscriptionAttributes;

    get adminWizards() {
      return getOwner(this).lookup("controller:admin-wizards");
    };

    get subscriptionLink() {
      return this.subscriptionLandingUrl;
    };

    get subscriptionCtaLink() {
        switch (this.subscriptionType) {
            case "none":
            return PRODUCT_PAGE;
            case "standard":
            return SUPPORT_MESSAGE;
            case "business":
            return SUPPORT_MESSAGE;
            case "community":
            return MANAGER_CATEGORY;
            default:
            return PRODUCT_PAGE;
        }
    };
}