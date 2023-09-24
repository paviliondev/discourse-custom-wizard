import Service from '@ember/service';
import { getOwner } from "discourse-common/lib/get-owner";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { equal } from "@ember/object/computed";

const PRODUCT_PAGE = "https://custom-wizard.pavilion.tech";
const SUPPORT_MESSAGE =
  "https://coop.pavilion.tech/new-message?username=support&title=Custom%20Wizard%20Support";
const MANAGER_CATEGORY =
  "https://discourse.pluginmanager.org/c/discourse-custom-wizard";

export default class SubscriptionService extends Service {
    @tracked subscribed = false;
    @tracked subscriptionType = "";
    @tracked businessSubscription = false;
    @tracked communitySubscription = false;
    @tracked standardSubscription = false;
    @tracked subscriptionAttributes = {};
    subscriptionLandingUrl = PRODUCT_PAGE;

    init() {
      super.init(...arguments);
      console.log("subscription initialisation");
      this.retrieveSubscriptionStatus();
    }

    retrieveSubscriptionStatus() {
      ajax("/admin/wizards/subscription").then(result => {
        console.log(result)
        this.subscribed = result.subscribed;
        this.subscriptionType = result.subscription_type;
        this.subscriptionAttributes = result.subscription_attributes;
        this.businessSubscription = equal(this.subscriptionType, "business");
        this.communitySubscription = equal(this.subscriptionType, "community");
        this.standardSubscription = equal(this.subscriptionType, "standard");
      })
      .catch(popupAjaxError);
    };

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