import CustomWizardAdmin from "../../models/custom-wizard-admin";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
  setupComponent(attrs, component) {
    CustomWizardAdmin.all()
      .then((result) => {
        component.set("wizardList", result);
      })
      .catch(popupAjaxError);

    component.set(
      "wizardListVal",
      attrs?.category?.custom_fields?.create_topic_wizard
    );
    component.set(
      "hideFromComposer",
      attrs?.category?.custom_fields?.custom_wizard_hide_from_composer
    );
  },

  actions: {
    changeWizard(wizard) {
      this.set("wizardListVal", wizard);
      this.set("category.custom_fields.create_topic_wizard", wizard);
    },
    toggleHideFromComposer() {
      this.toggleProperty("hideFromComposer");
      this.set(
        "category.custom_fields.custom_wizard_hide_from_composer",
        this.hideFromComposer
      );
    },
  },
};
