export default Ember.Route.extend({
  redirect() {
    this.transitionTo('custom.index');
  }
});
