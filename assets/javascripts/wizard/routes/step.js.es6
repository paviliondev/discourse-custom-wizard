import WizardI18n from "../lib/wizard-i18n";
import { getCachedWizard } from "../models/wizard";
import Route from "@ember/routing/route";

export default Route.extend({
  beforeModel() {
    this.set("wizard", getCachedWizard());
  },

  model(params) {
    const wizard = this.wizard;

    if (wizard && wizard.steps) {
      const step = wizard.steps.findBy("id", params.step_id);
      return step ? step : wizard.steps[0];
    } else {
      return wizard;
    }
  },

  afterModel(model) {
    if (model.completed) {
      return this.transitionTo("wizard.index");
    }
    return model.set("wizardId", this.wizard.id);
  },

  renderTemplate() {
    this.render("wizard/templates/step");
  },

  setupController(controller, model) {
    let props = {
      step: model,
      wizard: this.wizard,
    };

    if (!model.permitted) {
      props["stepMessage"] = {
        state: "not-permitted",
        text:
          model.permitted_message || WizardI18n("wizard.step_not_permitted"),
      };
      if (model.index > 0) {
        props["showReset"] = true;
      }
    }

    controller.setProperties(props);
  },
});
