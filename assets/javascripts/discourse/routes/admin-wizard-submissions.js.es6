import CustomWizard from '../models/custom-wizard';
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  beforeModel() {
    const param = this.paramsFor('adminWizardSubmissions').wizard_id;
    const wizards = this.modelFor('admin-wizards-submissions');
        
    if (wizards.length && (param === 'first')) {
      const wizard = wizards.get(`${param}Object`);
      if (wizard) {
        this.transitionTo('adminWizardSubmissions', wizard.id.dasherize());
      }
    }
  },
  
  model(params) {
    const wizardId = params.wizard_id;
    if (wizardId && wizardId !== 'new') {
      return CustomWizard.submissions(params.wizard_id);
    } else {
      return {};
    }
  },

  setupController(controller, model) {
    if (model.submissions) {
      let fields = [];
      model.submissions.forEach((s) => {
        Object.keys(s).forEach((k) => {
          if (fields.indexOf(k) < 0) {
            fields.push(k);
          }
        });
      });

      let submissions = [];
      model.submissions.forEach((s) => {
        let submission = {};
        fields.forEach((f) => {
          submission[f] = s[f];
        });
        submissions.push(submission);
      });
      
      console.log(model.id)

      controller.setProperties({
        wizard: model.wizard,
        submissions,
        fields
      });
    }
  }
});
