import { getOwner } from "discourse-common/lib/get-owner";

export default {
  shouldRender(attrs, ctx) {
    return ctx.siteSettings.wizard_important_notices_on_dashboard;
  },

  setupComponent() {
    const controller = getOwner(this).lookup("controller:admin-dashboard");
    const importantNotice = controller.get("customWizardImportantNotice");

    if (importantNotice) {
      this.set("importantNotice", importantNotice);
    }
  },
};
