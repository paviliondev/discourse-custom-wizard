import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed from "discourse-common/utils/decorators";
import getUrl from "discourse-common/lib/get-url";
import CustomWizardField from "./custom-wizard-field";
import CustomWizardStep from "./custom-wizard-step";

const CustomWizard = EmberObject.extend({
  @discourseComputed("steps.length")
  totalSteps: (length) => length,

  skip() {
    if (this.required && !this.completed && this.permitted) {
      return;
    }
    CustomWizard.skip(this.id);
  },

  restart() {
    CustomWizard.restart(this.id);
  },
});

CustomWizard.reopenClass({
  skip(wizardId) {
    ajax({ url: `/w/${wizardId}/skip`, type: "PUT" })
      .then((result) => {
        CustomWizard.finished(result);
      })
      .catch(popupAjaxError);
  },

  restart(wizardId) {
    ajax({ url: `/w/${wizardId}/skip`, type: "PUT" })
      .then(() => {
        window.location.href = `/w/${wizardId}`;
      })
      .catch(popupAjaxError);
  },

  finished(result) {
    let url = "/";
    if (result.redirect_on_complete) {
      url = result.redirect_on_complete;
    }
    window.location.href = getUrl(url);
  },

  build(wizardJson) {
    if (!wizardJson) {
      return null;
    }

    if (!wizardJson.completed && wizardJson.steps) {
      wizardJson.steps = wizardJson.steps
        .map((step) => {
          const stepObj = CustomWizardStep.create(step);
          stepObj.wizardId = wizardJson.id;

          stepObj.fields.sort((a, b) => {
            return parseFloat(a.number) - parseFloat(b.number);
          });

          let tabindex = 1;
          stepObj.fields.forEach((f) => {
            f.tabindex = tabindex;

            if (["date_time"].includes(f.type)) {
              tabindex = tabindex + 2;
            } else {
              tabindex++;
            }
          });

          stepObj.fields = stepObj.fields.map((f) => {
            f.wizardId = wizardJson.id;
            f.stepId = stepObj.id;
            return CustomWizardField.create(f);
          });

          return stepObj;
        })
        .sort((a, b) => {
          return parseFloat(a.index) - parseFloat(b.index);
        });
    }
    return CustomWizard.create(wizardJson);
  },
});

export function findCustomWizard(wizardId, params = {}) {
  let url = `/w/${wizardId}.json`;

  let paramKeys = Object.keys(params).filter((k) => {
    if (k === "wizard_id") {
      return false;
    }
    return !!params[k];
  });

  if (paramKeys.length) {
    url += "?";
    paramKeys.forEach((k, i) => {
      if (i > 0) {
        url += "&";
      }
      url += `${k}=${params[k]}`;
    });
  }

  return ajax(url).then((result) => {
    return CustomWizard.build(result);
  });
}

let _wizard_store;

export function updateCachedWizard(wizard) {
  _wizard_store = wizard;
}

export function getCachedWizard() {
  return _wizard_store;
}

export default CustomWizard;
