import wizardSchema from "../lib/wizard-schema";

export default {
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (siteSettings.wizard_apis_enabled) {
      wizardSchema.action.types.send_to_api = {
        api: null,
        api_endpoint: null,
        api_body: null,
      };
    }
  },
};
