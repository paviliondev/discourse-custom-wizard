import { action } from "@ember/object";
import Route from "@ember/routing/route";
import { service } from "@ember/service";
import { scrollTop } from "discourse/lib/scroll-top";
import I18n from "I18n";
import { getCachedWizard } from "../models/custom-wizard";

export default Route.extend({
  router: service(),

  beforeModel() {
    const wizard = getCachedWizard();
    this.set("wizard", wizard);

    if (!wizard || !wizard.permitted || wizard.completed) {
      this.router.replaceWith("customWizard");
    }
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
      return this.router.transitionTo("wizard.index");
    }
    return model.set("wizardId", this.wizard.id);
  },

  setupController(controller, model) {
    let props = {
      step: model,
      wizard: this.wizard,
    };

    if (!model.permitted) {
      props["stepMessage"] = {
        state: "not-permitted",
        text: model.permitted_message || I18n.t("wizard.step_not_permitted"),
      };
      if (model.index > 0) {
        props["showReset"] = true;
      }
    }

    controller.setProperties(props);
  },

  @action
  didTransition() {
    scrollTop();
    return true;
  },
});
