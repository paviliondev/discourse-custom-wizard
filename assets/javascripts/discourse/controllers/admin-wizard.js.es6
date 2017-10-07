import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({

  @computed('model.steps.[]', 'currentStep')
  stepLinks(steps, currentStep) {
    return steps.map((s) => {
      if (s) {
        const id = s.get('id');
        const title = s.get('title');

        let link = { id, title: title || id };

        let classes = 'btn';
        if (currentStep && id === currentStep.get('id')) {
          classes += ' btn-primary';
        };

        link['classes'] = classes;

        return link;
      }
    });
  },

  @computed('model.id', 'model.name')
  wizardUrl(wizardId) {
    return window.location.origin + '/wizard/custom/' + Ember.String.dasherize(wizardId);
  },

  actions: {
    save() {
      this.get('model').save().then(() => {
        if (this.get('newWizard')) {
          this.send("refreshAllWizards");
        } else {
          this.send("refreshWizard");
        }
      });
    },

    remove() {
      this.get('model').remove().then(() => {
        this.send("refreshAllWizards");
      });
    },

    addStep() {
      const steps = this.get('model.steps');
      const newNum = steps.length + 1;
      const step = Ember.Object.create({
        fields: Ember.A(),
        actions: Ember.A(),
        id: `step-${newNum}`
      });
      steps.pushObject(step);
      this.set('currentStep', step);
    },

    removeStep(stepId) {
      const steps = this.get('model.steps');
      steps.removeObject(steps.findBy('id', stepId));
      this.set('currentStep', steps[steps.length - 1]);
    },

    changeStep(stepId) {
      const steps = this.get('model.steps');
      this.set('currentStep', steps.findBy('id', stepId));
    }
  }
});
