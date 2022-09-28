import { A } from "@ember/array";
import EmberObject from "@ember/object";
import CustomWizardAdmin from "../models/custom-wizard-admin";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model(params) {
    return CustomWizardAdmin.submissions(params.wizardId);
  },

  setupController(controller, model) {
    let fields = [
      EmberObject.create({ id: "username", label: "User", enabled: true }),
    ];
    let submissions = [];

    model.submissions.forEach((s) => {
      let submission = {
        username: s.user,
      };

      Object.keys(s.fields).forEach((fieldId) => {
        if (!fields.some((field) => field.id === fieldId)) {
          fields.push(
            EmberObject.create({
              id: fieldId,
              label: s.fields[fieldId].label,
              enabled: true,
            })
          );
        }
        submission[fieldId] = s.fields[fieldId];
      });

      submission["submitted_at"] = s.submitted_at;
      submissions.push(EmberObject.create(submission));
    });

    let submittedAt = {
      id: "submitted_at",
      label: "Submitted At",
      enabled: true,
    };

    fields.push(EmberObject.create(submittedAt));

    controller.setProperties({
      wizard: model.wizard,
      fields: A(fields),
      submissions: A(submissions),
      total: model.total,
    });
  },
});
