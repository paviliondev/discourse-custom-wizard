import { findCustomWizard } from '../models/custom';
import { ajax } from 'wizard/lib/ajax';
import { getUrl } from 'discourse-common/lib/get-url';

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
  },

  actions: {
    finished(result) {
      let url = "/";
      if (result.topic_id) url += `t/${result.topic_id}`;
      document.location.replace(getUrl(url));
    }
  }
});
