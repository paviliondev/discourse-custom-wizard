import CustomWizard from "../../models/custom-wizard";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
  setupComponent(attrs, component) {
    CustomWizard.all()
      .then((result) => {
        component.set("wizardList", result);
      })
      .catch(popupAjaxError);
      attrs
    component.set(
      "wizardListVal",
      attrs?.category?.custom_fields?.create_topic_wizard
    );
  },

  actions: {
    changeWizard(wizard) {
      this.set("wizardListVal", wizard);
      this.set("category.custom_fields.create_topic_wizard", wizard);
    },
  },
};
