export default Ember.Route.extend({
  beforeModel() {
    const appModel = this.modelFor('custom');
    if (appModel.completed) {
      this.set('completed', true);
    } else if (appModel.start) {
      this.replaceWith('custom.step', appModel.start);
    }
  },

  setupController(controller) {
    const completed = this.get('completed');
    controller.set('completed', completed);
  }
});
