import CustomWizard from '../models/custom-wizard';
import { ajax } from 'discourse/lib/ajax';
import { selectKitContent, profileFields, generateName } from '../lib/wizard';
import DiscourseRoute from "discourse/routes/discourse";
import { all } from "rsvp";

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
    this.set('newWizard', wizardId === 'new');
    
    if (this.newWizard) {
      return CustomWizard.create();
    } else {      
      const wizard = this.modelFor('admin-wizards-custom')
        .findBy('id', wizardId.underscore());
      
      if (!wizard) {
        return this.transitionTo('adminWizard', 'new');
      } else {
        return wizard;
      }
    }
  },

  afterModel(model) {
    return all([
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
          selectKitContent([...result.types])
        )
      });
  },

  _getThemes(model) {
    return ajax('/admin/themes')
      .then((result) => {
        model.set('themes', result.themes.map(t => {
          return {
            id: t.id,
            name: t.name
          }
        }));
      });
  },

  _getApis(model) {
    return ajax('/admin/wizards/apis')
      .then((result) => model.set('apis', result));
  },
  
  _getUserFields(model) {
    return this.store.findAll('user-field').then((result) => {
      if (result && result.content) {
        model.set('userFields', 
          result.content.map((f) => ({
            id: `user_field_${f.id}`,
            name: f.name
          })).concat(
            profileFields.map((f) => ({
              id: f,
              name: generateName(f)
            }))
          )
        );
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
