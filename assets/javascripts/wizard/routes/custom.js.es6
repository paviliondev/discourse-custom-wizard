/* eslint no-undef: 0*/

import { findCustomWizard, updateCachedWizard } from "../models/custom";
import { ajax } from "wizard/lib/ajax";
import WizardI18n from "../lib/wizard-i18n";

export default Ember.Route.extend({
  beforeModel(transition) {
    this.set("queryParams", transition.intent.queryParams);
  },

  model(params) {
    return findCustomWizard(params.wizard_id, this.get("queryParams"));
  },

  renderTemplate() {
    this.render("custom");
    const wizardModel = this.modelFor("custom");
    const stepModel = this.modelFor("custom.step");

    if (wizardModel.get("first_step.id") !== stepModel.id) {
      const resumeDialog = bootbox.dialog(
        WizardI18n("wizard.incomplete_submission.title"),
        [
          {
            label: WizardI18n("wizard.incomplete_submission.restart"),
            callback: () => {
              wizardModel.restart();
            },
          },
          {
            label: WizardI18n("wizard.incomplete_submission.resume"),
            callback: () => {
              resumeDialog.modal("hide");
            },
          },
        ],
        {
          onEscape: false,
        }
      );
    }
  },

  afterModel(model) {
    updateCachedWizard(model);

    return ajax({
      url: `/site/settings`,
      type: "GET",
    }).then((result) => {
      $.extend(Wizard.SiteSettings, result);
    });
  },

  setupController(controller, model) {
    const background = model ? model.get("background") : "AliceBlue";
    Ember.run.scheduleOnce("afterRender", this, function () {
      $("body.custom-wizard").css("background", background);

      if (model && model.id) {
        $("#custom-wizard-main").addClass(model.id.dasherize());
      }
    });
    controller.setProperties({
      customWizard: true,
      logoUrl: Wizard.SiteSettings.logo_small,
      reset: null,
    });
  },
});
