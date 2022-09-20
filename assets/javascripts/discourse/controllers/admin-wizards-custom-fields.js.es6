import Controller from "@ember/controller";
import CustomWizardCustomField from "../models/custom-wizard-custom-field";

export default Controller.extend({
  messageKey: "create",
  fieldKeys: ["klass", "type", "name", "serializers"],
  documentationUrl: "https://discourse.pluginmanager.org/t/custom-fields",

  actions: {
    addField() {
      this.get("customFields").unshiftObject(
        CustomWizardCustomField.create({ edit: true })
      );
    },

    saveField(field) {
      return CustomWizardCustomField.saveField(field).then((result) => {
        if (result.success) {
          this.setProperties({
            messageKey: "saved",
            messageType: "success",
          });
        } else {
          if (result.messages) {
            this.setProperties({
              messageKey: "error",
              messageType: "error",
              messageOpts: { messages: result.messages },
            });
          }
        }

        setTimeout(
          () =>
            this.setProperties({
              messageKey: "create",
              messageType: null,
              messageOpts: null,
            }),
          10000
        );

        return result;
      });
    },

    removeField(field) {
      return CustomWizardCustomField.destroyField(field).then(() => {
        this.get("customFields").removeObject(field);
      });
    },
  },
});
