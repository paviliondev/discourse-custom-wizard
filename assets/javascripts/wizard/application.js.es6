import { buildResolver } from "discourse-common/resolver";
import Application from "@ember/application";
import WizardInitializer from "./lib/initialize/wizard";
import { isTesting } from "discourse-common/config/environment";

export default Application.extend({
  rootElement: "#custom-wizard-main",
  Resolver: buildResolver("discourse/plugins/discourse-custom-wizard/wizard"),

  customEvents: {
    paste: "paste",
  },

  start() {
    if (!isTesting()) {
      this.initializer(WizardInitializer);
    }
  },
});
