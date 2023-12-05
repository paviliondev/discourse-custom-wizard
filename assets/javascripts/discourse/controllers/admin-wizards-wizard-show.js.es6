import {
  default as discourseComputed,
  observes,
} from "discourse-common/utils/decorators";
import { notEmpty } from "@ember/object/computed";
import { inject as service } from "@ember/service";
import NextSessionScheduledModal from "../components/modal/next-session-scheduled";
import { generateId, wizardFieldList } from "../lib/wizard";
import { dasherize } from "@ember/string";
import { later, scheduleOnce } from "@ember/runloop";
import Controller from "@ember/controller";
import copyText from "discourse/lib/copy-text";
import I18n from "I18n";
import { filterValues } from "discourse/plugins/discourse-custom-wizard/discourse/lib/wizard-schema";

export default Controller.extend({
  modal: service(),
  hasName: notEmpty("wizard.name"),

  @observes("currentStep")
  resetCurrentObjects() {
    const currentStep = this.currentStep;

    if (currentStep) {
      const fields = currentStep.fields;
      this.set("currentField", fields && fields.length ? fields[0] : null);
    }

    scheduleOnce("afterRender", () => $("body").addClass("admin-wizard"));
  },

  @observes("wizard.name")
  setId() {
    const wizard = this.wizard;
    if (wizard && !wizard.existingId) {
      this.set("wizard.id", generateId(wizard.name));
    }
  },

  @discourseComputed("wizard.id")
  wizardUrl(wizardId) {
    let baseUrl = window.location.href.split("/admin");
    return baseUrl[0] + "/w/" + dasherize(wizardId);
  },

  @discourseComputed("wizard.after_time_scheduled")
  nextSessionScheduledLabel(scheduled) {
    return scheduled
      ? moment(scheduled).format("MMMM Do, HH:mm")
      : I18n.t("admin.wizard.after_time_time_label");
  },

  @discourseComputed(
    "currentStep.id",
    "wizard.save_submissions",
    "currentStep.fields.@each.label"
  )
  wizardFields(currentStepId, saveSubmissions) {
    let steps = this.wizard.steps;
    if (!saveSubmissions) {
      steps = [steps.findBy("id", currentStepId)];
    }
    return wizardFieldList(steps);
  },

  @discourseComputed("fieldTypes", "wizard.allowGuests")
  filteredFieldTypes(fieldTypes) {
    const fieldTypeIds = fieldTypes.map((f) => f.id);
    const allowedTypeIds = filterValues(
      this.wizard,
      "field",
      "type",
      fieldTypeIds
    );
    return fieldTypes.filter((f) => allowedTypeIds.includes(f.id));
  },

  getErrorMessage(result) {
    if (result.backend_validation_error) {
      return result.backend_validation_error;
    }

    let errorType = "failed";
    let errorParams = {};

    if (result.error) {
      errorType = result.error.type;
      errorParams = result.error.params;
    }

    return I18n.t(`admin.wizard.error.${errorType}`, errorParams);
  },

  actions: {
    save() {
      this.setProperties({
        saving: true,
        error: null,
      });

      const wizard = this.wizard;
      const creating = this.creating;
      let opts = {};

      if (creating) {
        opts.create = true;
      }

      wizard
        .save(opts)
        .then((result) => {
          if (result.wizard_id) {
            this.send("afterSave", result.wizard_id);
          } else if (result.errors) {
            this.set("error", result.errors.join(", "));
          }
        })
        .catch((result) => {
          this.set("error", this.getErrorMessage(result));

          later(() => this.set("error", null), 10000);
        })
        .finally(() => this.set("saving", false));
    },

    remove() {
      this.wizard.remove().then(() => this.send("afterDestroy"));
    },

    setNextSessionScheduled() {
      this.modal.show(NextSessionScheduledModal, {
        model: {
          dateTime: this.wizard.after_time_scheduled,
          update: (dateTime) =>
            this.set("wizard.after_time_scheduled", dateTime),
        },
      });
    },

    copyUrl() {
      const $copyRange = $('<p id="copy-range"></p>');
      $copyRange.html(this.wizardUrl);

      $(document.body).append($copyRange);

      if (copyText(this.wizardUrl, $copyRange[0])) {
        this.set("copiedUrl", true);
        later(() => this.set("copiedUrl", false), 2000);
      }

      $copyRange.remove();
    },
  },
});
