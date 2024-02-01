import DiscourseRoute from "discourse/routes/discourse";
import { buildFieldTypes, buildFieldValidations } from "../lib/wizard-schema";
import EmberObject, { set } from "@ember/object";
import { A } from "@ember/array";
import { all } from "rsvp";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

export default DiscourseRoute.extend({
  router: service(),

  model() {
    return ajax("/admin/wizards/wizard");
  },

  afterModel(model) {
    buildFieldTypes(model.field_types);
    buildFieldValidations(model.realtime_validations);

    return all([
      this._getThemes(model),
      this._getApis(model),
      this._getUserFields(model),
    ]);
  },

  _getThemes(model) {
    return ajax("/admin/themes").then((result) => {
      set(
        model,
        "themes",
        result.themes.map((t) => {
          return {
            id: t.id,
            name: t.name,
          };
        })
      );
    });
  },

  _getApis(model) {
    return ajax("/admin/wizards/api").then((result) =>
      set(model, "apis", result)
    );
  },

  _getUserFields(model) {
    return this.store.findAll("user-field").then((result) => {
      if (result && result.content) {
        set(
          model,
          "userFields",
          result.content.map((f) => ({
            id: `user_field_${f.id}`,
            name: f.name,
          }))
        );
      }
    });
  },

  currentWizard() {
    const params = this.paramsFor("adminWizardsWizardShow");

    if (params && params.wizardId) {
      return params.wizardId;
    } else {
      return null;
    }
  },

  setupController(controller, model) {
    controller.setProperties({
      wizardList: model.wizard_list,
      wizardId: this.currentWizard(),
      custom_fields: A(model.custom_fields.map((f) => EmberObject.create(f))),
    });
  },

  actions: {
    changeWizard(wizardId) {
      this.controllerFor("adminWizardsWizard").set("wizardId", wizardId);

      if (wizardId) {
        this.router.transitionTo("adminWizardsWizardShow", wizardId);
      } else {
        this.router.transitionTo("adminWizardsWizard");
      }
    },

    afterDestroy() {
      this.router.transitionTo("adminWizardsWizard").then(() => this.refresh());
    },

    afterSave(wizardId) {
      this.refresh().then(() => this.send("changeWizard", wizardId));
    },

    createWizard() {
      this.controllerFor("adminWizardsWizard").set("wizardId", "create");
      this.router.transitionTo("adminWizardsWizardShow", "create");
    },
  },
});
