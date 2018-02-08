import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  @computed('showPreview')
  togglePreviewLabel(showPreview) {
    return showPreview ? 'wizard_composer.hide_preview' : 'wizard_composer.show_preview';
  },

  actions: {
    togglePreview() {
      this.toggleProperty('showPreview');
    }
  }
});
