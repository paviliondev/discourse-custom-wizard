/* eslint no-undef: 0 */

import { findCustomWizard, updateCachedWizard } from "../models/custom";
import { ajax } from "wizard/lib/ajax";

export default Ember.Route.extend({
  beforeModel(transition) {
    this.set("queryParams", transition.intent.queryParams);
  },

  model(params) {
    return findCustomWizard(params.wizard_id, this.get("queryParams"));
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
