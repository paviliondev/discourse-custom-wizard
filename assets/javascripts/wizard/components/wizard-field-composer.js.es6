import { observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'wizard-field-composer',

  keyPress(e) {
    e.stopPropagation();
  },

  @observes('field.value')
  validate() {
    const minLength = Wizard.SiteSettings.min_post_length;
    const post = this.get('field.value');
    const field = this.get('field');

    field.set('customValidation', true);

    if (!post) {
      return field.setValid(false);
    }

    if (minLength && post.length < minLength) {
      return field.setValid(false, I18n.t('wizard.validation.too_short', { min: minLength }));
    }

    field.setValid(true);
  }
});
