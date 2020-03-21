import CustomWizard from '../models/custom-wizard';
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model(params) {
    return CustomWizard.submissions(params.wizard_id);
  },

  setupController(controller, model) {
    let fields = [];
    model.forEach((s) => {
      Object.keys(s).forEach((k) => {
        if (fields.indexOf(k) < 0) {
          fields.push(k);
        }
      });
    });

    let submissions = [];
    model.forEach((s) => {
      let submission = {};
      fields.forEach((f) => {
        submission[f] = s[f];
      });
      submissions.push(submission);
    });

    controller.setProperties({ submissions, fields });
  }
});
