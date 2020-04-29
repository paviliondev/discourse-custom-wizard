import { computed, set } from "@ember/object";
import { alias, equal, or, not } from "@ember/object/computed";
import { newPair, connectorContent, inputTypesContent, defaultSelectionType, defaultConnector } from '../lib/wizard-mapper';
import Component from "@ember/component";
import { observes } from "discourse-common/utils/decorators";
import { A } from "@ember/array";

export default Component.extend({
  classNameBindings: [':mapper-input', 'inputType'],
  inputType: alias('input.type'),
  isConditional: equal('inputType', 'conditional'),
  isAssignment: equal('inputType', 'assignment'),
  isAssociation: equal('inputType', 'association'),
  isValidation: equal('inputType', 'validation'),
  hasOutput: or('isConditional', 'isAssignment'),
  hasPairs: or('isConditional', 'isAssociation', 'isValidation'),
  canAddPair: not('isAssignment'),
  connectors: computed(function() { return connectorContent('output', this.input.type, this.options) }),
  inputTypes: computed(function() { return inputTypesContent(this.options) }),
  
  @observes('input.type')
  setupType() {
    if (this.hasPairs && (!this.input.pairs || this.input.pairs.length < 1)) {
      this.send('addPair');
    }
    
    if (this.hasOutput) {
      this.set('input.output', null);
      
      if (!this.input.outputConnector) {
        const options = this.options;
        this.set('input.output_type', defaultSelectionType('output', options));
        this.set('input.output_connector', defaultConnector('output', this.inputType, options));
      }
    }
  },
    
  actions: {
    addPair() {
      if (!this.input.pairs) {
        this.set('input.pairs', A());
      }
      
      const pairs = this.input.pairs;
      const pairCount = pairs.length + 1;
            
      pairs.forEach(p => (set(p, 'pairCount', pairCount)));
      
      pairs.pushObject(
        newPair(
          this.input.type, 
          Object.assign(
            {},
            this.options,
            { index: pairs.length, pairCount }
          )
        )
      );
    },
    
    removePair(pair) {
      const pairs = this.input.pairs;
      const pairCount = pairs.length - 1;
      
      pairs.forEach(p => (set(p, 'pairCount', pairCount)));
      pairs.removeObject(pair);
    }
  }
});
