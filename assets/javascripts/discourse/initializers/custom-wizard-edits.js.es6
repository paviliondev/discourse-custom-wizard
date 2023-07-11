import DiscourseURL from "discourse/lib/url";
import { withPluginApi } from "discourse/lib/plugin-api";
import getUrl from "discourse-common/lib/get-url";
import { observes } from "discourse-common/utils/decorators";
import { dasherize } from "@ember/string";

export default {
  name: "custom-wizard-edits",
  initialize(container) {
    const messageBus = container.lookup("service:message-bus");
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.custom_wizard_enabled) {
      return;
    }

    messageBus.subscribe("/redirect_to_wizard", function (wizardId) {
      const wizardUrl = window.location.origin + "/w/" + wizardId;
      window.location.href = wizardUrl;
    });

    withPluginApi("0.8.36", (api) => {
      api.onAppEvent("page:changed", (data) => {
        const currentUser = container.lookup("service:current-user");
        const settings = container.lookup("service:site-settings");
        if (currentUser) {
          const redirectToWizard = currentUser.redirect_to_wizard;
          const excludedPaths = settings.wizard_redirect_exclude_paths
            .split("|")
            .concat(["loading"]);
          if (
            redirectToWizard &&
            data.currentRouteName !== "customWizardStep" &&
            !excludedPaths.find((p) => {
              return data.currentRouteName.indexOf(p) > -1;
            })
          ) {
            DiscourseURL.routeTo(`/w/${dasherize(redirectToWizard)}`);
          }
        }
      });

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
          if (
            this.session.wizardEventFieldId === this.fieldId &&
            this.element
          ) {
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
