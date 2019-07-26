import { observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  @observes('categories')
  setValue() {
    const categories = this.get('categories');
    if (categories.length) {
      const limit = this.get('field.limit');
      const property = this.get('field.property') || 'id';
      let value = limit === 1 ? categories[0][property] : categories.map(c => c[property]);
      this.set('field.value', value);
    }
  }
});