import DiscourseURL from "discourse/lib/url";
import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import CustomWizardNotice from "../models/custom-wizard-notice";
import { A } from "@ember/array";

export default {
  name: "custom-wizard-edits",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    if (!siteSettings.custom_wizard_enabled) {
      return;
    }

    const existing = DiscourseURL.routeTo;
    DiscourseURL.routeTo = function (path, opts) {
      if (path && path.indexOf("/w/") > -1) {
        return (window.location = path);
      }
      return existing.apply(this, [path, opts]);
    };

    withPluginApi("0.8.36", (api) => {
      api.modifyClass('route:admin-dashboard', {
        afterModel() {
          return CustomWizardNotice.list().then(result => {
            if (result && result.length) {
              this.set('notices', A(result.map(n => CustomWizardNotice.create(n))));
            }
         });
        },

        setupController(controller, model) {
          if (this.notices) {
            let warningNotices = this.notices.filter(n => n.type === 'warning');

            if (warningNotices.length) {
              controller.set('wizardWarningNotice', warningNotices[0]);
            }
          }

          this._super(...arguments);
        }
      });
    });
  },
};
