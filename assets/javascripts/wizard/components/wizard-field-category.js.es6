import { observes } from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';

export default Ember.Component.extend({
  didInsertElement() {
    const value = this.get('field.value');
    if (value) {
      const property = this.get('field.property') || 'id';
      const categories = [...value].map(v => {
        return property === 'id' ?
               Category.findById(v) :
               Category.findBySlug(v);
      });
      this.set('categories', categories);
    }
  },

  @observes('categories')
  setValue() {
    const categories = this.get('categories');
    if (categories.length) {
      const property = this.get('field.property') || 'id';
      let value = categories.length === 1 ?
                  categories[0][property] :
                  categories.map(c => c[property]);
      this.set('field.value', value);
    }
  }
});