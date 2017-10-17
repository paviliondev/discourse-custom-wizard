import { findCustomWizard } from '../models/custom';
import { ajax } from 'wizard/lib/ajax';

export default Ember.Route.extend({
  model(params) {
    return findCustomWizard(params.wizard_id);
  },

  afterModel() {
    return ajax({
      url: `/site/settings`,
      type: 'GET',
    }).then((result) => {
      Object.assign(Wizard.SiteSettings, result);
    });
  },

  setupController(controller, model) {
    Ember.run.scheduleOnce('afterRender', this, function(){
      $('body.custom-wizard').css('background', model.get('background'));
    });

    controller.setProperties({
      customWizard: true,
      logoUrl: Wizard.SiteSettings.logo_small_url
    });
  }
});
