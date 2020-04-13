import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  beforeModel(transition) {
    if (transition.targetName === "adminWizards.index") {
      this.transitionTo('adminWizardsWizard');
    }
  },
});