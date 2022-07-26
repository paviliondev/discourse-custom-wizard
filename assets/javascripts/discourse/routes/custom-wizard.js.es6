import { findCustomWizard, updateCachedWizard } from "../models/wizard";
import I18n from "I18n";
import Route from "@ember/routing/route";

export default Route.extend({
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
    });

    const stepModel = this.modelFor("step");
    if (
      model.resume_on_revisit &&
      model.submission_last_updated_at &&
      stepModel.index > 0
    ) {
      this.showDialog(model);
    }
  },

  getWizardBackground() {
    const wizard = this.controllerFor("custom-wizard").get("model");
    return wizard ? wizard.get("background") : "";
  },

  activate() {
    if (!document.body.classList.contains("custom-wizard")) {
      document.body.classList.add("custom-wizard");
    }

    const background = this.getWizardBackground();
    if (background) {
      document.body.style.background = background;
    }
  },

  deactivate() {
    if (document.body.classList.contains("custom-wizard")) {
      document.body.classList.remove("custom-wizard");
    }

    const background = this.getWizardBackground();
    if (background) {
      document.body.style.background = "";
    }
  },
});
