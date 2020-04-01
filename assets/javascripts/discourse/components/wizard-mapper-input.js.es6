import { computed, set } from "@ember/object";
import { alias, equal } from "@ember/object/computed";
import { newPair, connectorContent, inputTypesContent } from '../lib/mapper';

export default Ember.Component.extend({
  classNameBindings: [':mapper-input', 'type'],
  inputType: alias('input.type'),
  isConditional: equal('inputType', 'conditional'),
  hasOutput: alias('options.hasOutput'),
  hasPairs: computed('hasOutput', 'isConditional', function() { return !this.hasOutput || this.isConditional; }),
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
