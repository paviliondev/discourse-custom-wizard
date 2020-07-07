import CustomWizard from '../models/custom-wizard';
import { ajax } from 'discourse/lib/ajax';
import DiscourseRoute from "discourse/routes/discourse";
import I18n from "I18n";

export default DiscourseRoute.extend({
  model(params) {
    if (params.wizardId === 'create') {
      return { create: true };
    } else {
      return ajax(`/admin/wizards/wizard/${params.wizardId}`);
    }
  },
  
  afterModel(model) {
    if (model.none) {
      return this.transitionTo('adminWizardsWizard');
    }
  },

  setupController(controller, model) {
    const parentModel = this.modelFor('adminWizardsWizard');
    const wizard = CustomWizard.create((!model || model.create) ? {} : model);
    const fieldTypes = Object.keys(parentModel.field_types).map(type => {
      return {
        id: type,
        name: I18n.t(`admin.wizard.field.type.${type}`)
      };
    })
              
    let props = {
      wizardList: parentModel.wizard_list,
      fieldTypes,
      userFields: parentModel.userFields,
      apis: parentModel.apis,
      themes: parentModel.themes,
      wizard,
      currentStep: wizard.steps[0],
      currentAction: wizard.actions[0],
      creating: model.create
    };
    
    controller.setProperties(props);
  }
});
