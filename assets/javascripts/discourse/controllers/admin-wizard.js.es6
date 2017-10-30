import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  @computed('model.id', 'model.name')
  wizardUrl(wizardId) {
    return window.location.origin + '/w/' + Ember.String.dasherize(wizardId);
  },

  actions: {
    save() {
      this.setProperties({
        saving: true,
        error: null
      });
      const wizard = this.get('model');
      wizard.save().then(() => {
        this.set('saving', false);
        if (this.get('newWizard')) {
          this.send("refreshAllWizards");
        } else {
          this.send("refreshWizard");
        }
      }).catch((result) => {
        console.log(result)
        this.set('saving', false);
        this.set('error', I18n.t(`admin.wizard.error.${result.error}`));
        Ember.run.later(() => this.set('error', null), 10000);
      });
    },

    remove() {
      this.get('model').remove().then(() => {
        this.send("refreshAllWizards");
      });
    }
  }
});
