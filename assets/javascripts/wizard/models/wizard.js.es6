import { default as computed } from "discourse-common/utils/decorators";
import getUrl from "discourse-common/lib/get-url";
import Field from "./field";
import { ajax } from "../lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Step from "./step";
import EmberObject from "@ember/object";
import Site from "./site";

const CustomWizard = EmberObject.extend({
  @computed("steps.length")
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
          const stepObj = Step.create(step);
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
            return Field.create(f);
          });

          return stepObj;
        })
        .sort((a, b) => {
          return parseFloat(a.index) - parseFloat(b.index);
        });
    }

    if (wizardJson.categories) {
      let subcatMap = {};
      let categoriesById = {};
      let categories = wizardJson.categories.map((c) => {
        if (c.parent_category_id) {
          subcatMap[c.parent_category_id] =
            subcatMap[c.parent_category_id] || [];
          subcatMap[c.parent_category_id].push(c.id);
        }
        return (categoriesById[c.id] = EmberObject.create(c));
      });

      // Associate the categories with their parents
      categories.forEach((c) => {
        let subcategoryIds = subcatMap[c.get("id")];
        if (subcategoryIds) {
          c.set(
            "subcategories",
            subcategoryIds.map((id) => categoriesById[id])
          );
        }
        if (c.get("parent_category_id")) {
          c.set("parentCategory", categoriesById[c.get("parent_category_id")]);
        }
      });

      Site.currentProp("categories", categories);
      Site.currentProp("listByActivity", categories);
      Site.currentProp("categoriesById", categoriesById);
      Site.currentProp(
        "uncategorized_category_id",
        wizardJson.uncategorized_category_id
      );
    }

    return CustomWizard.create(wizardJson);
  },
});

export function findCustomWizard(wizardId, params = {}) {
  let url = `/w/${wizardId}`;

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

  return ajax({ url, cache: false, dataType: "json" }).then((result) => {
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
