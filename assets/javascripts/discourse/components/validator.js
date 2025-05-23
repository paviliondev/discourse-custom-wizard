import Component from "@ember/component";
import { equal } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  classNames: ["validator"],
  classNameBindings: ["isValid", "isInvalid"],
  validMessageKey: null,
  invalidMessageKey: null,
  isValid: null,
  isInvalid: equal("isValid", false),

  init() {
    this._super(...arguments);

    if (this.get("validation.backend")) {
      // set a function that can be called as often as it need to
      // from the derived component
      this.backendValidate = (params) => {
        return ajax("/realtime-validations", {
          data: {
            type: this.get("type"),
            ...params,
          },
        });
      };
    }
  },

  didInsertElement() {
    this._super(...arguments);
    this.appEvents.on("custom-wizard:validate", this, this.checkIsValid);
  },

  willDestroyElement() {
    this._super(...arguments);
    this.appEvents.off("custom-wizard:validate", this, this.checkIsValid);
  },

  checkIsValid() {
    this.set("isValid", this.validate());
  },
});
