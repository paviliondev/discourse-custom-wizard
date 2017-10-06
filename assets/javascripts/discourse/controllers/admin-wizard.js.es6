import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({

  @computed('model.steps.[]', 'currentStep')
  stepLinks(steps, currentStep) {
    return steps.map((s) => {
      if (s) {
        let link = {
          id: s.get('id'),
          title: s.get('title')
        };

        let classes = 'btn';
        if (currentStep && s.get('id') === currentStep.get('id')) {
          classes += ' btn-primary';
        };

        link['classes'] = classes;

        return link;
      }
    });
  },

  @computed('model.id')
  wizardUrl(wizardId) {
    return window.location.origin + '/wizard/custom/' + wizardId;
  },

  actions: {
    save() {
      this.get('model').save().then(() => {
        this.send("refreshRoute");
      });
    },

    remove() {
      this.get('model').remove().then(() => {
        this.transitionToRoute('adminWizardsCustom');
      });
    },

    addStep() {
      const steps = this.get('model.steps');
      const newNum = steps.length + 1;
      const step = Ember.Object.create({
        fields: Ember.A(),
        actions: Ember.A(),
        title: `Step ${newNum}`,
        id: `step-${newNum}`
      });

      steps.pushObject(step);
      this.set('currentStep', step);
    },

    removeStep(stepId) {
      const steps = this.get('model.steps');
      steps.removeObject(steps.findBy('id', stepId));
    },

    changeStep(stepId) {
      const steps = this.get('model.steps');
      this.set('currentStep', steps.findBy('id', stepId));
    }
  }
});
