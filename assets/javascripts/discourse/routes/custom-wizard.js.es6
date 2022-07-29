import { findCustomWizard, updateCachedWizard } from "../models/custom-wizard";
import I18n from "I18n";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  titleToken() {
    const wizard = this.modelFor("custom-wizard");
    return wizard ? wizard.name || wizard.id : I18n.t("wizard.custom_title");
  },

  beforeModel(transition) {
    if (transition.intent.queryParams) {
      this.set("queryParams", transition.intent.queryParams);
    }
  },

  model(params) {
    return findCustomWizard(params.wizard_id, this.get("queryParams"));
  },

  showDialog(wizardModel) {
    const title = I18n.t("wizard.incomplete_submission.title", {
      date: moment(wizardModel.submission_last_updated_at).format(
        "MMMM Do YYYY"
      ),
    });

    const buttons = [
      {
        label: I18n.t("wizard.incomplete_submission.restart"),
        class: "btn btn-default",
        callback: () => {
          wizardModel.restart();
        },
      },
      {
        label: I18n.t("wizard.incomplete_submission.resume"),
        class: "btn btn-primary",
      },
    ];

    const options = {
      onEscape: false,
    };

    bootbox.dialog(title, buttons, options);
  },

  afterModel(model) {
    updateCachedWizard(model);
  },

  setupController(controller, model) {
    controller.setProperties({
      customWizard: true,
      logoUrl: this.siteSettings.logo_small,
      reset: null,
      model,
    });

    const stepModel = this.modelFor("custom-wizard-step");
    if (
      model.resume_on_revisit &&
      model.submission_last_updated_at &&
      stepModel.index > 0
    ) {
      this.showDialog(model);
    }

    const background = model.get("background");
    if (background) {
      document.body.style.background = background;
    }
  },

  activate() {
    if (!document.body.classList.contains("custom-wizard")) {
      document.body.classList.add("custom-wizard");
    }
  },

  deactivate() {
    if (document.body.classList.contains("custom-wizard")) {
      document.body.classList.remove("custom-wizard");
    }

    document.body.style.background = "";
  },
});
