import CustomWizard from '../models/custom-wizard';

export default Discourse.Route.extend({
  model(params) {
    return Ember.RSVP.hash({
      submissions: CustomWizard.submissions(params.wizard_id),
      wizard: this.modelFor('admin-wizards-submissions').findBy('id', params.wizard_id)
    });
  },

  setupController(controller, model) {
    let fields = ['user'];

    model.wizard.steps.forEach((s) => {
      if (s.fields) {
        s.fields.forEach((f) => {
          fields.push(f.id);
        });
      };
    });

    controller.setProperties({
      submissions: model.submissions,
      fields
    });
  }
});
