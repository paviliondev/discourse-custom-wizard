import { getOwner } from 'discourse-common/lib/get-owner';
import { on } from 'discourse-common/utils/decorators';
import { newInput } from '../lib/custom-wizard';
import { default as discourseComputed } from 'discourse-common/utils/decorators';

export default Ember.Component.extend({
  classNames: 'field-mapper',
  
  @discourseComputed('inputs.[]', 'options.singular')
  canAdd(inputs, singular) {
    return !singular || !inputs || inputs.length < 1;
  },

  actions: {
    add() {
      if (!this.get('inputs')) this.set('inputs', Ember.A());            
      this.get('inputs').pushObject(newInput(this.options));
    },

    remove(input) {
      this.get('inputs').removeObject(input);
    }
  }
});
