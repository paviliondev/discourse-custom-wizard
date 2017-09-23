import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model() {
    return CustomWizard.findAll();
  },

  setupController(controller, model){
    controller.set("model", model.toArray());
  },

  actions: {
    willTransition(transition) {
      if (transition.intent.name === 'adminWizardsCustom') {
        this.refresh();
      }
    }
  }
});
