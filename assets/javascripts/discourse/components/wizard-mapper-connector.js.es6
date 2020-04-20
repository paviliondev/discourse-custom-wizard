import Component from "@ember/component";
import { gt } from '@ember/object/computed';
import { computed } from "@ember/object";
import { defaultConnector } from '../lib/wizard-mapper';
import { later } from "@ember/runloop";
import { observes } from "discourse-common/utils/decorators";

export default Component.extend({
  classNameBindings: [':mapper-connector', ':mapper-block', 'hasMultiple::single'],
  hasMultiple: gt('connectors.length', 1),
  connectorLabel: computed(function() {
    let key = this.connector;
    let path = this.inputTypes ? `input.${key}.name` : `connector.${key}`;
    return I18n.t(`admin.wizard.${path}`);
  }),
  
  didReceiveAttrs() {
    if (!this.connector) {
      later(() => {
        this.set(
          'connector',
          defaultConnector(this.connectorType, this.inputType, this.options)
        );
      });  
    }
  },
  
  @observes('connector')
  updated() {
    this.onUpdate('connector');
  }
});