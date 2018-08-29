import { withPluginApi } from 'discourse/lib/plugin-api';
import DiscourseURL from 'discourse/lib/url';

export default {
  name: 'custom-wizard-edits',
  initialize() {
    withPluginApi('0.8.12', api => {
      api.modifyClass('component:global-notice', {
        buildBuffer(buffer) {
          this._super(...arguments);
          const wizards = this.site.get('complete_custom_wizard');
          if (wizards) {
            wizards.forEach((w) => {
              const text = I18n.t('wizard.complete_custom', {
                wizard_url: w.url,
                wizard_name: w.name,
                site_name: this.siteSettings.title
              });
              buffer.push(`<div class='row'><div class='alert alert-info alert-wizard'>${text}</div></div>`);
            });
          }
        }
      });
    });

    const existing = DiscourseURL.routeTo;
    DiscourseURL.routeTo = function(path, opts) {
      if (path && path.indexOf('/w/') > -1) {
        return window.location = path;
      }
      return existing.apply(this, [path, opts]);
    };
  }
};
