import { withPluginApi } from 'discourse/lib/plugin-api';
import DiscourseURL from 'discourse/lib/url';

export default {
  name: 'custom-wizard-edits',
  initialize(container) {
    const siteSettings = container.lookup('site-settings:main');
    
    if (!siteSettings.custom_wizard_enabled) return;

    const existing = DiscourseURL.routeTo;
    DiscourseURL.routeTo = function(path, opts) {
      if (path && path.indexOf('/w/') > -1) {
        return window.location = path;
      }
      return existing.apply(this, [path, opts]);
    };
  }
};
