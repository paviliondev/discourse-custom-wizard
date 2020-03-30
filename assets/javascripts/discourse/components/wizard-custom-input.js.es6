import {
  newPair,
  generateSelectKitContent,
  defaultInputType
} from '../lib/custom-wizard';
import {
  default as discourseComputed,
  on
} from 'discourse-common/utils/decorators';
import { computed, set } from "@ember/object";
import { alias } from "@ember/object/computed";

export default Ember.Component.extend({
  classNameBindings: [':custom-input', 'type'],
  inputType: alias('input.type'),
  outputConnector: computed('inputTypes', function() {
    const key = this.outputConnectorKey || `admin.wizard.input.${this.type}.output`;
    return I18n.t(key).toLowerCase();
  }),
  
  @on('init')
  setDefaults() {
    if (!this.type) this.set('type', defaultInputType(this.options));
  },
  
  @discourseComputed('options.allowedInputs')
  allowedInputs(option) {
    return option || 'conditional,assignment';
  },
  
  @discourseComputed('allowedInputs')
  inputTypes(allowedInputs) {
    return allowedInputs.split(',').map((type) => {
      return {
        id: type,
        name: I18n.t(`admin.wizard.input.${type}.prefix`)
      }
    });
  },
  
  @discourseComputed('options.hasOutput', 'input.type')
  hasPairs(hasOutput, inputType) {
    return !hasOutput || inputType === 'conditional';
  },
  
  @discourseComputed('input.type')
  hasOutputConnector(inputType) {
    return inputType === 'conditional';
  },
  
  actions: {
    addPair() {
      const pairs = this.get('input.pairs');
      
      const pairCount = pairs.length + 1;
      pairs.forEach(p => (set(p, 'pairCount', pairCount)));
      
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
      pairs.forEach(p => (set(p, 'pairCount', pairCount)));
      pairs.removeObject(pair);
    }
  }
});
