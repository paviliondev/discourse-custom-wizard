import DiscourseRoute from "discourse/routes/discourse";
import CustomWizardApi from '../models/custom-wizard-api';

export default DiscourseRoute.extend({
  model() {
    return CustomWizardApi.list();
  },
  
  setupController(controller, model) {
    const showParams = this.paramsFor('adminWizardsApiShow');
    const apiName = showParams.name == 'create' ? null : showParams.name;
    const apiList = (model || []).map(api => {
      return {
        id: api.name,
        name: api.title
      }
    });
        
    controller.setProperties({
      apiName,
      apiList
    })
  },
  
  actions: {
    changeApi(apiName) {
      this.controllerFor('adminWizardsApi').set('apiName', apiName);
      this.transitionTo('adminWizardsApiShow', apiName);
    },
    
    afterDestroy() {
      this.transitionTo('adminWizardsApi').then(() => this.refresh());
    },
    
    afterSave(apiName) {
      this.refresh().then(() => this.send('changeApi', apiName));
    },
    
    createApi() {
      this.controllerFor('adminWizardsApi').set('apiName', 'create');
      this.transitionTo('adminWizardsApiShow', 'create');
    }
  }
  
});