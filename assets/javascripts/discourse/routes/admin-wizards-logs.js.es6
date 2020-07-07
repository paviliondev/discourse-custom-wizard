import CustomWizardLogs from '../models/custom-wizard-logs';
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardLogs.list();
  },

  setupController(controller, model) {
    controller.set('logs', model);
  }
})
