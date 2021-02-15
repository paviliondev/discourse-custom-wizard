import Component from "@ember/component";
import { not } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";
import { getToken } from "wizard/lib/ajax";

export default Component.extend({
  classNameBindings: ["isValid", "isInvalid"],
  validMessageKey: null,
  invalidMessageKey: null,
  isValid: null,
  isInvalid: not("isValid"),
  layoutName: "components/validator", // useful for sharing the template with extending components
  init() {
    this._super(...arguments);

    if (this.get("validation.backend")) {
      // set a function that can be called as often as it need to
      // from the derived component
      this.backendValidate = (params) => {
        return ajax("/realtime-validations", {
          data: {
            validation: this.get("name"),
            authenticity_token: getToken(),
            ...params,
          },
        });
      };
    }
  },

  didInsertElement() {
    this.appEvents.on("custom-wizard:validate", this, this.checkIsValid);
  },

  willDestroyElement() {
    this.appEvents.off("custom-wizard:validate", this, this.checkIsValid);
  },

  checkIsValid() {
    this.set("isValid", this.validate());
  },
});
