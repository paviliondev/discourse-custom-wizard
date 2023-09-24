import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  afterModel(model, transition) {
    if (transition.targetName === "adminWizards.index") {
      this.transitionTo("adminWizardsWizard");
    }
  },
});
