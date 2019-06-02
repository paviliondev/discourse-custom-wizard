import CustomWizardApi from '../models/custom-wizard-api';

export default Discourse.Route.extend({
  queryParams: {
    refresh_list: {
      refreshModel: true
    }
  },

  model(params) {
    if (params.name === 'new') {
      return CustomWizardApi.create({ isNew: true });
    } else {
      return CustomWizardApi.find(params.name);
    }
  },

  setupController(controller, model){
    controller.set("api", model);
  }
});
