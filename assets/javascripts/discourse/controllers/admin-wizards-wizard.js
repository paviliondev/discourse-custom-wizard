import Controller from "@ember/controller";
import { equal } from "@ember/object/computed";
import { default as discourseComputed } from "discourse-common/utils/decorators";

export default Controller.extend({
  creating: equal("wizardId", "create"),

  @discourseComputed("creating", "wizardId")
  wizardListVal(creating, wizardId) {
    return creating ? null : wizardId;
  },

  @discourseComputed("creating", "wizardId")
  messageKey(creating, wizardId) {
    let key = "select";
    if (creating) {
      key = "create";
    } else if (wizardId) {
      key = "edit";
    }
    return key;
  },

  messageUrl:
    "https://pavilion.tech/products/discourse-custom-wizard-plugin/documentation/",
});
