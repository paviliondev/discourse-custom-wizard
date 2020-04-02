import Component from "@ember/component";
import { lt } from '@ember/object/computed';
import { computed } from "@ember/object";

export default Component.extend({
  classNameBindings: [':mapper-connector', ':mapper-block', 'single'],
  single: lt('connectors.length', 2),
  connectorLabel: computed(function() {
    let key = this.connector;
    let path = this.inputTypes ? `input.${key}.name` : `connector.${key}`;
    return I18n.t(`admin.wizard.${path}`);
  })
});