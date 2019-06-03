import CustomWizard from '../models/custom-wizard';
import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  beforeModel() {
    const param = this.paramsFor('adminWizard').wizard_id;
    const wizards = this.modelFor('admin-wizards-custom');

    if (wizards.length && (param === 'first' || param === 'last')) {
      const wizard = wizards.get(`${param}Object`);
      if (wizard) {
        this.transitionTo('adminWizard', wizard.id.dasherize());
      }
    }
  },

  model(params) {
    const wizardId = params.wizard_id;

    if (wizardId === 'new') {
      this.set('newWizard', true);
      return CustomWizard.create();
    };
    this.set('newWizard', false);

    const wizard = this.modelFor('admin-wizards-custom').findBy('id', wizardId.underscore());

    if (!wizard) return this.transitionTo('adminWizard', 'new');

    return wizard;
  },

  afterModel(model) {
    return Ember.RSVP.all([
      this._getFieldTypes(model),
      this._getThemes(model),
      this._getApis(model)
    ]);
  },

  _getFieldTypes(model) {
    return ajax('/admin/wizards/field-types')
      .then((result) => model.set('fieldTypes', result.types));
  },

  _getThemes(model) {
    return this.store.findAll('theme').then((result) => {
      model.set('themes', result.content);
    });
  },

  _getApis(model) {
    return ajax('/admin/wizards/apis')
      .then((result) => model.set('apis', result));
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
