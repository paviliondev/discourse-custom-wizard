import { newPair } from '../lib/custom-wizard';

export default Ember.Component.extend({
  classNames: 'custom-input',
  outputConnectorKey: 'admin.wizard.connector.prefill',
  outputPrefixKey: 'admin.wizard.if',
  
  actions: {
    addPair() {
      this.get('input.pairs').pushObject(
        newPair(this.options, this.input.pairs.length)
      );
    },
    
    removePair(pair) {
      this.get('input.pairs').removeObject(pair);
    }
  }
});
