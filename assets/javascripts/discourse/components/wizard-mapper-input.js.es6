import { computed, set } from "@ember/object";
import { alias, equal, or } from "@ember/object/computed";
import { newPair, connectorContent, inputTypesContent } from '../lib/wizard-mapper';
import Component from "@ember/component";
import { observes } from "discourse-common/utils/decorators";

export default Component.extend({
  classNameBindings: [':mapper-input', 'type'],
  inputType: alias('input.type'),
  isConditional: equal('inputType', 'conditional'),
  isAssignment: equal('inputType', 'assignment'),
  isPair: equal('inputType', 'pair'),
  hasOutput: or('isConditional', 'isAssignment'),
  hasPairs: or('isConditional', 'isPair'),
  connectors: computed(function() { return connectorContent('output', this.input.type, this.options) }),
  inputTypes: computed(function() { return inputTypesContent(this.options) }),
    
  actions: {
    addPair() {
      const pairs = this.input.pairs;
      const pairCount = pairs.length + 1;
      
      pairs.forEach(p => (set(p, 'pairCount', pairCount)));
      
      pairs.pushObject(
        newPair(
          this.input.type,
          Object.assign(
            {},
            this.options,
            { 
              index: pairs.length,
              pairCount,
            }
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
