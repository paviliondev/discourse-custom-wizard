import CustomWizardAdmin from "../models/custom-wizard-admin";
import DiscourseRoute from "discourse/routes/discourse";

const excludedMetaFields = ["route_to", "redirect_on_complete", "redirect_to"];

export default DiscourseRoute.extend({
  model(params) {
    return CustomWizardAdmin.submissions(params.wizardId);
  },

  setupController(controller, model) {
    if (model && model.submissions) {
      let fields = ["username"];
      model.submissions.forEach((s) => {
        Object.keys(s.fields).forEach((k) => {
          if (!excludedMetaFields.includes(k) && fields.indexOf(k) < 0) {
            fields.push(k);
          }
        });
      });

      let submissions = [];
      model.submissions.forEach((s) => {
        let submission = {
          username: s.username,
        };
        Object.keys(s.fields).forEach((f) => {
          if (fields.includes(f)) {
            submission[f] = s.fields[f];
          }
        });
        submissions.push(submission);
      });

      controller.setProperties({
        wizard: model.wizard,
        submissions,
        fields,
      });
    }
  },
});
