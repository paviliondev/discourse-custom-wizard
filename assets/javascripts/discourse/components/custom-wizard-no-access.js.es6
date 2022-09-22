import CustomWizard from "../models/custom-wizard";
import discourseComputed from "discourse-common/utils/decorators";
import Component from "@ember/component";
import { dasherize } from "@ember/string";
import getURL from "discourse-common/lib/get-url";

export default Component.extend({
  classNameBindings: [":wizard-no-access", "reasonClass"],

  @discourseComputed("reason")
  reasonClass(reason) {
    return dasherize(reason);
  },

  @discourseComputed
  siteName() {
    return this.siteSettings.title || "";
  },

  actions: {
    skip() {
      if (this.currentUser) {
        CustomWizard.skip(this.get("wizardId"));
      } else {
        window.location = getURL("/");
      }
    },
  },
});
