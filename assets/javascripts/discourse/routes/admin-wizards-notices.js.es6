import CustomWizardNotice from "../models/custom-wizard-notice";
import DiscourseRoute from "discourse/routes/discourse";
import { A } from "@ember/array";

export default DiscourseRoute.extend({
  model() {
    return CustomWizardNotice.list({ include_all: true });
  },

  setupController(controller, model) {
    controller.setProperties({
      notices: A(
        model.notices.map((notice) => CustomWizardNotice.create(notice))
      ),
    });
  },
});
