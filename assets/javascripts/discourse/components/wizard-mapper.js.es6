import { getOwner } from 'discourse-common/lib/get-owner';
import { on } from 'discourse-common/utils/decorators';
import { newInput } from '../lib/wizard-mapper';
import { default as discourseComputed } from 'discourse-common/utils/decorators';

export default Ember.Component.extend({
  classNames: 'wizard-mapper',
  
  @discourseComputed('inputs.[]', 'options.singular')
  canAdd(inputs, singular) {
    return !singular || !inputs || inputs.length < 1;
  },
  
  @discourseComputed('options')
  inputOptions(options) {
    return {
      hasOutput: options.hasOutput || false,
      inputTypes: options.inputTypes || null,
      pairConnector: options.pairConnector || null,
      outputConnector: options.outputConnector || null,
      textSelection: options.textSelection || true,
      wizardSelection: options.wizardSelection || false,
      userFieldSelection: options.userFieldSelection || false,
      categorySelection: options.categorySelection || false,
      tagSelection: options.tagSelection || false,
      groupSelection: options.groupSelection || false,
      userSelection: options.userSelection || false,
      keyDefaultSelection: options.keyDefaultSelection || null,
      valueDefaultSelection: options.valueDefaultSelection || null,
      outputDefaultSelection: options.outputDefaultSelection || null
    }
  },

  actions: {
    add() {
      if (!this.get('inputs')) this.set('inputs', Ember.A());            
      this.get('inputs').pushObject(newInput(this.inputOptions));
    },

    remove(input) {
      this.get('inputs').removeObject(input);
    }
  }
});
