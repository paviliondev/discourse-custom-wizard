export default Discourse.Route.extend({
  redirect() {
    this.transitionTo('adminWizardsCustom');
  }
});
