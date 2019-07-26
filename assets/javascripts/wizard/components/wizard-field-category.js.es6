import { observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  @observes('categories')
  setValue() {
    const categories = this.get('categories');
    this.set('field.value', categories.map(c => c.id));
  }
});