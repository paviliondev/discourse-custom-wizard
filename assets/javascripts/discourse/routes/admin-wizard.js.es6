import CustomWizard from '../models/custom-wizard';
import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  model(params) {
    if (params.wizard_id === 'new') {
      this.set('newWizard', true);
      return CustomWizard.create();
    };
    this.set('newWizard', false);

    const wizard = this.modelFor('admin-wizards-custom').findBy('id', params.wizard_id.underscore());
    if (!wizard) return this.transitionTo('adminWizardsCustom.index');

    return wizard;
  },

  afterModel(model) {
    return ajax('/admin/wizards/field-types')
      .then((result) => model.set('fieldTypes', result.types));
  },

  setupController(controller, model) {
    const newWizard = this.get('newWizard');
    const steps = model.get('steps') || [];
    controller.setProperties({
      newWizard,
      model,
      currentStep: steps[0]
    });
  },

  actions: {
    refreshWizard() {
      this.refresh();
    }
  }
});
