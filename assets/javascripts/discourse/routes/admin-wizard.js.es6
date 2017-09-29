import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model(params) {
    if (params.wizard_id === 'new') {
      this.set('new', true);
      return CustomWizard.create();
    }
    this.set('new', false);

    const wizard = this.modelFor('admin-wizards-custom').findBy('id', params.wizard_id);
    if (!wizard) return this.transitionTo('adminWizardsCustom.index');

    return wizard;
  },

  setupController(controller, model) {
    controller.set("new", this.get('new'));
    controller.set("model", model);
  }
});
