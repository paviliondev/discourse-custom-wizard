import CustomWizardLogs from '../models/custom-wizard-logs';

export default Discourse.Route.extend({
  model() {
    return CustomWizardLogs.list();
  },
  
  setupController(controller, model) {
    controller.set('logs', model);
  }
})