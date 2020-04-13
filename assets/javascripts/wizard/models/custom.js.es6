import { default as computed } from 'discourse-common/utils/decorators';
import getUrl from 'discourse-common/lib/get-url';
import WizardField from 'wizard/models/wizard-field';
import { ajax } from 'wizard/lib/ajax';
import Step from 'wizard/models/step';
import EmberObject from "@ember/object";

const CustomWizard = EmberObject.extend({
  @computed('steps.length')
  totalSteps: length => length,

  skip() {
    if (this.required && (!this.completed && this.permitted)) return;
    CustomWizard.skip(this.id);
  },
});

CustomWizard.reopenClass({
  skip(wizardId) {
    ajax({ url: `/w/${wizardId}/skip`, type: 'PUT' }).then((result) => {
      CustomWizard.finished(result);
    });
  },

  finished(result) {
    let url = "/";
    if (result.redirect_on_complete) {
      url = result.redirect_on_complete;
    }
    window.location.href = getUrl(url);
  }
});

export function findCustomWizard(wizardId, params = {}) {
  let url = `/w/${wizardId}`;

  let paramKeys = Object.keys(params).filter(k => {
    if (k === 'wizard_id') return false;
    return !!params[k];
  });

  if (paramKeys.length) {
    url += '?';
    paramKeys.forEach((k,i) => {
      if (i > 0) {
        url += '&';
      }
      url += `${k}=${params[k]}`;
    });
  }

  return ajax({ url, cache: false, dataType: 'json' }).then(result => {
    const wizard = result;
    if (!wizard) return null;

    if (!wizard.completed) {
      wizard.steps = wizard.steps.map(step => {
        const stepObj = Step.create(step);
        stepObj.fields = stepObj.fields.map(f => WizardField.create(f));
        return stepObj;
      });
    }

    if (wizard.categories) {
      let subcatMap = {};
      let categoriesById = {};
      let categories = wizard.categories.map(c => {
        if (c.parent_category_id) {
          subcatMap[c.parent_category_id] =
            subcatMap[c.parent_category_id] || [];
          subcatMap[c.parent_category_id].push(c.id);
        }
        return (categoriesById[c.id] = EmberObject.create(c));
      });

      // Associate the categories with their parents
      categories.forEach(c => {
        let subcategoryIds = subcatMap[c.get("id")];
        if (subcategoryIds) {
          c.set("subcategories", subcategoryIds.map(id => categoriesById[id]));
        }
        if (c.get("parent_category_id")) {
          c.set("parentCategory", categoriesById[c.get("parent_category_id")]);
        }
      });

      Discourse.Site.currentProp('categoriesList', categories);
      Discourse.Site.currentProp('sortedCategories', categories);
      Discourse.Site.currentProp('listByActivity', categories);
      Discourse.Site.currentProp('categoriesById', categoriesById);
      Discourse.Site.currentProp('uncategorized_category_id', wizard.uncategorized_category_id);
    }

    return CustomWizard.create(wizard);
  });
};

export default CustomWizard;
