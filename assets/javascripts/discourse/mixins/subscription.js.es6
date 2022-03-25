import Mixin from "@ember/object/mixin";
import { getOwner } from "discourse-common/lib/get-owner";
import { readOnly } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";

export default Mixin.create({
  subscriptionLandingUrl: "https://custom-wizard.pavilion.tech",
  subscriptionClientUrl: "/admin/plugins/subscription-client",

  @discourseComputed
  adminWizards() {
    return getOwner(this).lookup("controller:admin-wizards");
  },

  subscribed: readOnly("adminWizards.subscribed"),
  subscriptionType: readOnly("adminWizards.subscriptionType"),
  businessSubscription: readOnly("adminWizards.businessSubscription"),
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
});
