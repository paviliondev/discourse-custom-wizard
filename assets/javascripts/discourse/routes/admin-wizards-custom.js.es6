import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model() {
    return CustomWizard.findAll();
  },

  afterModel(model) {
    const transitionToWizard = this.get('transitionToWizard');
    if (transitionToWizard === 'last' && model.length) {
      this.transitionTo('adminWizard', model[model.length - 1].id);
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
