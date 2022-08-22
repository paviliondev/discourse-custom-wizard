import DiscourseURL from "discourse/lib/url";
import { withPluginApi } from "discourse/lib/plugin-api";
import getUrl from "discourse-common/lib/get-url";
import { observes } from "discourse-common/utils/decorators";

export default {
  name: "custom-wizard-edits",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

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

    withPluginApi("0.8.7", (api) => {
      api.modifyClass("component:d-navigation", {
        pluginId: "custom-wizard",
        actions: {
          clickCreateTopicButton() {
            let createTopicWizard = this.get(
              "category.custom_fields.create_topic_wizard"
            );
            if (createTopicWizard) {
              window.location.href = getUrl(`/w/${createTopicWizard}`);
            } else {
              this._super();
            }
          },
        },
      });

      api.modifyClass("component:uppy-image-uploader", {
        pluginId: "custom-wizard",
        // Needed to ensure appEvents get registered when navigating between steps
        @observes("id")
        initOnStepChange() {
          if (/wizard-field|wizard-step/.test(this.id)) {
            this._initialize();
          }
        },
      });

      api.modifyClass("component:d-editor", {
        pluginId: "custom-wizard",

        didInsertElement() {
          this._super(...arguments);

          if (this.wizardComposer) {
            this.appEvents.on(
              `wizard-editor:insert-text`,
              this,
              "_wizardInsertText"
            );
            this.appEvents.on(
              "wizard-editor:replace-text",
              this,
              "_wizardReplaceText"
            );
          }
        },

        _wizardInsertText(text, options) {
          if (this.session.wizardEventFieldId === this.fieldId) {
            this.insertText(text, options);
          }
        },

        _wizardReplaceText(oldVal, newVal, opts = {}) {
          if (this.session.wizardEventFieldId === this.fieldId) {
            this.replaceText(oldVal, newVal, opts);
          }
        },
      });
    });
  },
};
