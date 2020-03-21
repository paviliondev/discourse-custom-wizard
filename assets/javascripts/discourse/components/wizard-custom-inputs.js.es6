import { getOwner } from 'discourse-common/lib/get-owner';
import { on } from 'discourse-common/utils/decorators';
import { newInput } from '../lib/custom-wizard';

export default Ember.Component.extend({
  classNames: 'custom-inputs',

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
