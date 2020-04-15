import { observes } from 'discourse-common/utils/decorators';
import Category from 'discourse/models/category';

export default Ember.Component.extend({
  didInsertElement() {
    const property = this.field.property || 'id';
    const value = this.field.value;
    
    if (value) {
      this.set('categories', [...value].reduce((result, v) => {
        let val = property === 'id' ? Category.findById(v) : Category.findBySlug(v);
        if (val) result.push(val);
        return result;
      }, []));
    }
  },
  
  @observes('categories')
  setValue() {
    const categories = (this.categories || []).filter(c => !!c);
    const property = this.field.property || 'id';
    
    if (categories.length) {            
      this.set('field.value', categories.reduce((result, c) => {
        if (c && c[property]) {
          result.push(c[property])
        }
        return result;
      }, []));
    }
  }
});