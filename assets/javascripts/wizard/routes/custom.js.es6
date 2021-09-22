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

    if (wizardModel.resume_on_revisit && stepModel.index > 0) {
      this.showDialog(wizardModel);
    }
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
