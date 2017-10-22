import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model(params) {
    return CustomWizard.submissions(params.wizard_id);
  },

  setupController(controller, model) {
    controller.set("model", model);
  }
});
