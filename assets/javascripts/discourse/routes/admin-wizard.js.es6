import CustomWizard from '../models/custom-wizard';
import { ajax } from 'discourse/lib/ajax';

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

  afterModel(model) {
    return ajax('/admin/wizards/field-types')
      .then((result) => model.set('fieldTypes', result.types));
  },

  setupController(controller, model) {
    controller.set("new", this.get('new'));
    controller.set("model", model);
  }
});
