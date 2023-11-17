import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

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

  async init() {
    super.init(...arguments);
    await this.retrieveSubscriptionStatus();
  }

  async retrieveSubscriptionStatus() {
    let result = await ajax("/admin/wizards/subscription").catch(
      popupAjaxError
    );

    this.subscribed = result.subscribed;
    this.subscriptionType = result.subscription_type;
    this.subscriptionAttributes = result.subscription_attributes;
    this.businessSubscription = this.subscriptionType === "business";
    this.communitySubscription = this.subscriptionType === "community";
    this.standardSubscription = this.subscriptionType === "standard";
  }

  async updateSubscriptionStatus() {
    let result = await ajax(
      "/admin/wizards/subscription?update_from_remote=true"
    ).catch(popupAjaxError);

    this.subscribed = result.subscribed;
    this.subscriptionType = result.subscription_type;
    this.subscriptionAttributes = result.subscription_attributes;
    this.businessSubscription = this.subscriptionType === "business";
    this.communitySubscription = this.subscriptionType === "community";
    this.standardSubscription = this.subscriptionType === "standard";
  }

  get subscriptionLink() {
    return this.subscriptionLandingUrl;
  }

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
  }
}
