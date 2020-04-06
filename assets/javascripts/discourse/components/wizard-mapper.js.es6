import { getOwner } from 'discourse-common/lib/get-owner';
import { on } from 'discourse-common/utils/decorators';
import { newInput, selectionTypes } from '../lib/wizard-mapper';
import { default as discourseComputed, observes } from 'discourse-common/utils/decorators';
import Component from "@ember/component";
import { A } from "@ember/array";

export default Component.extend({
  classNames: 'wizard-mapper',
  
  @discourseComputed('inputs.[]', 'options.singular')
  canAdd(inputs, singular) {
    return !singular || !inputs || inputs.length < 1;
  },
  
  @discourseComputed('options.@each')
  inputOptions(options) {
    let result = {
      inputTypes: options.inputTypes || 'conditional,assignment',
      pairConnector: options.pairConnector || null,
      outputConnector: options.outputConnector || null,
      context: options.context || null
    }
    
    let inputTypes = ['key', 'value', 'output'];
    inputTypes.forEach(type => {
      result[`${type}Placeholder`] = options[`${type}Placeholder`] || null;
      result[`${type}DefaultSelection`] = options[`${type}DefaultSelection`] || null;
    });
    
    selectionTypes.forEach(type => {
      if (options[`${type}Selection`]) {
        result[`${type}Selection`] = options[`${type}Selection`]
      } else {
        result[`${type}Selection`] = type === 'text' ? true : false;
      }
    });
                    
    return result;
  },

  actions: {
    add() {
      if (!this.get('inputs')) {
        this.set('inputs', A());
      }

      this.get('inputs').pushObject(newInput(this.inputOptions));
    },

    remove(input) {
      this.get('inputs').removeObject(input);
    }
  }
});
