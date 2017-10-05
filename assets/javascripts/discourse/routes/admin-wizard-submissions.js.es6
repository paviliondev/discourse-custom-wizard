export default Discourse.Route.extend({
  model(params) {
    return this.modelFor('admin-wizards-submissions').findBy('id', params.wizard_id);
  },

  setupController(controller, model) {
    controller.set("model", model);
  }
});
