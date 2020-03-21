import CustomWizard from '../models/custom-wizard';
import { ajax } from 'discourse/lib/ajax';
import {
  generateSelectKitContent,
  profileFields,
  generateName
} from '../lib/custom-wizard';
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
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
      this._getApis(model),
      this._getUserFields(model)
    ]);
  },

  _getFieldTypes(model) {
    return ajax('/admin/wizards/field-types')
      .then((result) => {
        model.set(
          'fieldTypes',
          generateSelectKitContent([...result.types])
        )
      });
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
  
  _getUserFields(model) {
    return this.store.findAll('user-field').then((result) => {
      if (result && result.content) {
        let userContent = result.content.map((f) => {
          return { id: `user_field_${f.id}`, name: f.name};
        });
        let profileContent = profileFields.map((f) => {
          return { id: f, name: generateName(f) };
        });
        model.set('userFields', userContent.concat(profileContent));
      }
    });
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
