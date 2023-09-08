import DiscourseURL from "discourse/lib/url";
import { withPluginApi } from "discourse/lib/plugin-api";
import { dasherize } from "@ember/string";

export default {
  name: "custom-wizard-redirect",
  after: "message-bus",

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
        const currentUser = api.getCurrentUser();

        if (currentUser) {
          const redirectToWizard = currentUser.redirect_to_wizard;
          const excludedPaths = siteSettings.wizard_redirect_exclude_paths
            .split("|")
            .concat(["loading"]);
          if (
            redirectToWizard &&
            !data.url.includes("ignore_redirect") &&
            data.currentRouteName !== "customWizardStep" &&
            !excludedPaths.find((p) => {
              return data.currentRouteName.indexOf(p) > -1;
            })
          ) {
            DiscourseURL.routeTo(`/w/${dasherize(redirectToWizard)}`);
          }
        }
      });
    });
  },
};
