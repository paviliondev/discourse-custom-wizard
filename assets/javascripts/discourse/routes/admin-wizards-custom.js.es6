import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model() {
    return CustomWizard.all();
  },

  afterModel(model) {
    const transitionToWizard = this.get('transitionToWizard');
    if (transitionToWizard && model.length) {
      this.set('transitionToWizard', null);
      this.transitionTo('adminWizard', transitionToWizard);
    };
  },

  setupController(controller, model){
    controller.set("model", model.toArray());
  },

  actions: {
    refreshAllWizards() {
      this.set('transitionToWizard', 'last');
      this.refresh();
    }
  }
});
