import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from 'discourse/lib/ajax';

export default DiscourseRoute.extend({
  model() {
    return ajax(`/admin/wizards/wizard`);
  },
  
  setupController(controller, model) {
    const showParams = this.paramsFor('adminWizardsSubmissionsShow');
        
    controller.setProperties({
      wizardId: showParams.wizardId,
      wizardList: model.wizard_list
    })
  },
  
  actions: {
    changeWizard(wizardId) {
      this.controllerFor('adminWizardsSubmissions').set('wizardId', wizardId);
      this.transitionTo('adminWizardsSubmissionsShow', wizardId);
    }
  }
});