import EmberObject from "@ember/object";
import ValidState from "discourse/plugins/discourse-custom-wizard/discourse/mixins/valid-state";
import { ajax } from "discourse/lib/ajax";
import discourseComputed from "discourse-common/utils/decorators";
import { later } from "@ember/runloop";
import { translationOrText } from "discourse/plugins/discourse-custom-wizard/discourse/lib/wizard";

export default EmberObject.extend(ValidState, {
  id: null,

  @discourseComputed("wizardId", "id")
  i18nKey(wizardId, stepId) {
    return `${wizardId}.${stepId}`;
  },

  @discourseComputed("i18nKey", "title")
  translatedTitle(i18nKey, title) {
    return translationOrText(`${i18nKey}.title`, title);
  },

  @discourseComputed("i18nKey", "description")
  translatedDescription(i18nKey, description) {
    return translationOrText(`${i18nKey}.description`, description);
  },

  @discourseComputed("index")
  displayIndex: (index) => index + 1,

  @discourseComputed("fields.[]")
  fieldsById(fields) {
    const lookup = {};
    fields.forEach((field) => (lookup[field.get("id")] = field));
    return lookup;
  },

  validate() {
    let allValid = true;
    const result = { warnings: [] };

    this.fields.forEach((field) => {
      allValid = allValid && field.check();
      const warning = field.get("warning");
      if (warning) {
        result.warnings.push(warning);
      }
    });

    this.setValid(allValid);

    return result;
  },

  fieldError(id, description) {
    const field = this.fields.findBy("id", id);
    if (field) {
      field.setValid(false, description);
    }
  },

  save() {
    const wizardId = this.get("wizardId");
    const fields = {};

    this.get("fields").forEach((f) => {
      if (f.type !== "text_only") {
        fields[f.id] = f.value;
      }
    });

    return ajax({
      url: `/w/${wizardId}/steps/${this.get("id")}`,
      type: "PUT",
      data: { fields },
    }).catch((response) => {
      if (response.jqXHR) {
        response = response.jqXHR;
      }
      if (response && response.responseJSON && response.responseJSON.errors) {
        let wizardErrors = [];
        response.responseJSON.errors.forEach((err) => {
          if (err.field === wizardId) {
            wizardErrors.push(err.description);
          } else if (err.field) {
            this.fieldError(err.field, err.description);
          } else if (err) {
            wizardErrors.push(err);
          }
        });
        if (wizardErrors.length) {
          this.handleWizardError(wizardErrors.join("\n"));
        }
        this.animateInvalidFields();
        throw response;
      }

      if (response && response.responseText) {
        const responseText = response.responseText;
        const start = responseText.indexOf(">") + 1;
        const end = responseText.indexOf("plugins");
        const message = responseText.substring(start, end);
        this.handleWizardError(message);
        throw message;
      }
    });
  },

  handleWizardError(message) {
    this.set("message", {
      state: "error",
      text: message,
    });
    later(() => this.set("message", null), 6000);
  },
});
