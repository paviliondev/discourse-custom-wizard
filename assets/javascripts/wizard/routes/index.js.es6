import Route from "@ember/routing/route";

export default Route.extend({
  beforeModel(transition) {
    if (transition.intent.params) {
      this.transitionTo("wizard");
    }
  },
});
