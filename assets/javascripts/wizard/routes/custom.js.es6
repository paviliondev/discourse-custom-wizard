/* eslint no-undef: 0 */

import { findCustomWizard } from '../models/custom';
import { ajax } from 'wizard/lib/ajax';

export default Ember.Route.extend({
  model(params) {
    let opts = {};
    if (params.reset == 'true') opts['reset'] = true;
    return findCustomWizard(params.wizard_id, opts);
  },

  afterModel() {
    return ajax({
      url: `/site/settings`,
      type: 'GET',
    }).then((result) => {
      $.extend(Wizard.SiteSettings, result);
    });
  },

  setupController(controller, model) {
    const background = model ? model.get('background') : 'AliceBlue';
    Ember.run.scheduleOnce('afterRender', this, function(){
      $('body.custom-wizard').css('background', background);
      if (model) {
        $('#custom-wizard-main').addClass(model.get('id').dasherize());
      }
    });

    controller.setProperties({
      customWizard: true,
      logoUrl: Wizard.SiteSettings.logo_small
    });
  }
});
