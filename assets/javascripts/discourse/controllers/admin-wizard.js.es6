export default Ember.Controller.extend({
  actions: {
    save() {
      this.get('model').save().then(() => {
        this.transitionToRoute('adminWizardsCustom');
      });
    },

    remove() {
      this.get('model').destroy().then(() => {
        this.transitionToRoute('adminWizardsCustom');
      });
    },

    addStep() {
      this.get('model.steps').pushObject({
        fields: Ember.A(),
        actions: Ember.A()
      });
    },

    removeStep(name) {
      this.get('model.steps').findBy('name', name);
    }
  }
});
