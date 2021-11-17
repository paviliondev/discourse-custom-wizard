import { getOwner } from "discourse-common/lib/get-owner";

export default {
  shouldRender(attrs, ctx) {
    return ctx.siteSettings.wizard_critical_notices_on_dashboard;
  },

  setupComponent(attrs, component) {
    const controller = getOwner(this).lookup("controller:admin-dashboard");

    component.set("notices", controller.get("customWizardCriticalNotices"));
    controller.addObserver("customWizardCriticalNotices.[]", () => {
      if (this._state === "destroying") {
        return;
      }
      component.set("notices", controller.get("customWizardCriticalNotices"));
    });
  },
};
