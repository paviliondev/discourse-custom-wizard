import CustomWizard from "../models/wizard";
import discourseComputed from "discourse-common/utils/decorators";
import Component from "@ember/component";
import { dasherize } from "@ember/string";

export default Component.extend({
  classNameBindings: [":wizard-no-access", "reasonClass"],
  layoutName: "wizard/templates/components/wizard-no-access",

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
      CustomWizard.skip(this.get("wizardId"));
    },
  },
});
