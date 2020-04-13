import Component from "@ember/component";
import { gt } from '@ember/object/computed';
import { computed } from "@ember/object";

export default Component.extend({
  classNameBindings: [':mapper-connector', ':mapper-block', 'hasMultiple::single'],
  hasMultiple: gt('connectors.length', 1),
  connectorLabel: computed(function() {
    let key = this.connector;
    let path = this.inputTypes ? `input.${key}.name` : `connector.${key}`;
    return I18n.t(`admin.wizard.${path}`);
  })
});