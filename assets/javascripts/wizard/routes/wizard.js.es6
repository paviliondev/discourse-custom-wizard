import { findCustomWizard, updateCachedWizard } from "../models/wizard";
import WizardI18n from "../lib/wizard-i18n";
import Route from "@ember/routing/route";
import { scheduleOnce } from "@ember/runloop";
import { getOwner } from "discourse-common/lib/get-owner";

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
    const title = WizardI18n("wizard.incomplete_submission.title", {
      date: moment(wizardModel.submission_last_updated_at).format(
        "MMMM Do YYYY"
      ),
    });

    const buttons = [
      {
        label: WizardI18n("wizard.incomplete_submission.restart"),
        class: "btn btn-default",
        callback: () => {
          wizardModel.restart();
        },
      },
      {
        label: WizardI18n("wizard.incomplete_submission.resume"),
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

  renderTemplate() {
    this.render("wizard/templates/wizard");
  },

  setupController(controller, model) {
    const background = model ? model.get("background") : "";

    scheduleOnce("afterRender", this, function () {
      $("body").css("background", background);

      if (model && model.id) {
        $(getOwner(this).rootElement).addClass(model.id.dasherize());
      }
    });

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
});
