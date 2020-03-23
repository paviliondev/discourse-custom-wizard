import { newPair } from '../lib/custom-wizard';
import { computed } from "@ember/object";

export default Ember.Component.extend({
  classNames: 'custom-input',
  outputConnector: computed(function() {
    return I18n.t(this.outputConnectorKey || 'admin.wizard.output.connector').toLowerCase();
  }),
  
  actions: {
    addPair() {
      const pairs = this.get('input.pairs');
      
      const pairCount = pairs.length + 1;
      pairs.forEach(p => (p.set('pairCount', pairCount)));
      
      pairs.pushObject(
        newPair(Object.assign(
          {},
          this.options,
          { 
            index: pairs.length,
            pairCount,
          }
        ))
      );
    },
    
    removePair(pair) {
      const pairs = this.get('input.pairs');
      const pairCount = pairs.length - 1;
      pairs.forEach(p => (p.set('pairCount', pairCount)));
      pairs.removeObject(pair);
    }
  }
});
