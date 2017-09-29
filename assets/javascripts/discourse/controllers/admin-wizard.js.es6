export default Ember.Controller.extend({
  actions: {
    save() {
      this.get('model').save().then(() => {
        this.transitionToRoute('adminWizardsCustom');
      });
    },

    remove() {
      this.get('model').remove().then(() => {
        this.transitionToRoute('adminWizardsCustom');
      });
    },

    addStep() {
      this.get('model.steps').pushObject(Ember.Object.create({
        fields: Ember.A(),
        actions: Ember.A()
      }));
    },

    removeStep(step) {
      this.get('model.steps').removeObject(step);
    }
  }
});
