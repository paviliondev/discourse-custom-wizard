import Component from "@ember/component";
import { computed } from "@ember/object";
import { gt } from "@ember/object/computed";
import { later } from "@ember/runloop";
import I18n from "I18n";
import { defaultConnector } from "../lib/wizard-mapper";

export default Component.extend({
  classNameBindings: [
    ":mapper-connector",
    ":mapper-block",
    "hasMultiple::single",
  ],
  hasMultiple: gt("connectors.length", 1),
  connectorLabel: computed(function () {
    let key = this.connector;
    let path = this.inputTypes ? `input.${key}.name` : `connector.${key}`;
    return I18n.t(`admin.wizard.${path}`);
  }),

  didReceiveAttrs() {
    this._super();
    if (!this.connector) {
      later(() => {
        this.set(
          "connector",
          defaultConnector(this.connectorType, this.inputType, this.options)
        );
      });
    }
  },

  actions: {
    changeConnector(value) {
      this.set("connector", value);
      this.onUpdate("connector", this.connectorType);
    },
  },
});
