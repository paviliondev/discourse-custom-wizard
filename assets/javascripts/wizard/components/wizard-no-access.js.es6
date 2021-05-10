import CustomWizard from "../models/custom";

export default Ember.Component.extend({
  siteName: function () {
    /*eslint no-undef:0*/
    return Wizard.SiteSettings.title;
  }.property(),

  actions: {
    skip() {
      CustomWizard.skip(this.get("wizardId"));
    },
  },
});
