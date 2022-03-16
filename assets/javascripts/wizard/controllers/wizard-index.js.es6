import Controller from "@ember/controller";
import { or } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";

const reasons = {
  noWizard: "none",
  requiresLogin: "requires_login",
  notPermitted: "not_permitted",
  completed: "completed",
};

export default Controller.extend({
  noAccess: or("noWizard", "requiresLogin", "notPermitted", "completed"),

  @discourseComputed("noAccessReason")
  noAccessI18nKey(reason) {
    return reason ? `wizard.${reasons[reason]}` : "wizard.none";
  },

  @discourseComputed
  noAccessReason() {
    return Object.keys(reasons).find((reason) => this.get(reason));
  },
});
