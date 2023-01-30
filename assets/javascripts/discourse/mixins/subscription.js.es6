import Mixin from "@ember/object/mixin";
import { getOwner } from "discourse-common/lib/get-owner";
import { readOnly } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";

const PRODUCT_PAGE = "https://custom-wizard.pavilion.tech";
const SUPPORT_MESSAGE =
  "https://coop.pavilion.tech/new-message?username=support&title=Custom%20Wizard%20Support";
const MANAGER_CATEGORY =
  "https://discourse.pluginmanager.org/c/discourse-custom-wizard";

export default Mixin.create({
  subscriptionLandingUrl: PRODUCT_PAGE,
  subscriptionClientUrl: "/admin/plugins/subscription-client",

  @discourseComputed
  adminWizards() {
    return getOwner(this).lookup("controller:admin-wizards");
  },

  subscribed: readOnly("adminWizards.subscribed"),
  subscriptionType: readOnly("adminWizards.subscriptionType"),
  businessSubscription: readOnly("adminWizards.businessSubscription"),
  communitySubscription: readOnly("adminWizards.communitySubscription"),
  standardSubscription: readOnly("adminWizards.standardSubscription"),
  subscriptionAttributes: readOnly("adminWizards.subscriptionAttributes"),
  subscriptionClientInstalled: readOnly(
    "adminWizards.subscriptionClientInstalled"
  ),

  @discourseComputed("subscriptionClientInstalled")
  subscriptionLink(subscriptionClientInstalled) {
    return subscriptionClientInstalled
      ? this.subscriptionClientUrl
      : this.subscriptionLandingUrl;
  },

  @discourseComputed("subscriptionType")
  subscriptionCtaLink(subscriptionType) {
    switch (subscriptionType) {
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
  },
});
