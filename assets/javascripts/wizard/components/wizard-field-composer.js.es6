import { default as computed, observes } from 'discourse-common/utils/decorators';

export default Ember.Component.extend({
  showPreview: false,
  elementId: "reply-control",
  classNameBindings: ["showPreview:show-preview:hide-preview"],
  
  didInsertElement() {
    this.set('composer', Ember.Object.create({
      loading: false,
      reply: this.get('field.value')
    }))
  },
  
  @observes('composer.reply')
  setField() {
    this.set('field.value', this.get('composer.reply'));
  },
  
  @computed('showPreview')
  togglePreviewLabel(showPreview) {
    return showPreview ? 'wizard_composer.hide_preview' : 'wizard_composer.show_preview';
  },

  actions: {
    togglePreview() {
      this.toggleProperty('showPreview');
    },
    
    groupsMentioned() {
    },
    afterRefresh() {
    },               
    cannotSeeMention() {
    },
    importQuote() {
    },
    showUploadSelector() {
    }
  }
});
